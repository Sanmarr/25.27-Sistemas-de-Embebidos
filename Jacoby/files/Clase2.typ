= Clase 2

== Bit Band

#figure(
  image("/images/bitband.png", width: 70%)
) 


Una CPU no puede modificar bits individuales de una posición de
memoria (o de un registro).La CPU solo puede modificar bytes o
words completos en cada acceso. Si la CPU desea modificar un bit
de un registro (o posición de memoria), debe hacer una copia de
este ultimo en un registro temporario modificar dicho bit mediante
operaciones lógicas  y
finalmente escribir el valor modificado al lugar original.
Esta forma de modificar bits individuales usando operaciones del
tipo `Read`-`Modify`-`Write` (no-atomicas) funciona bien cuando se hace una operación
a la vez, pero puede generar problemas cuando dos o mas
aplicaciones acceden de manera concurrente a ese registro (o
posición de memoria). Por ejemplo que ocurre si una interrupción
se produce entre la lectura y la modificación ? El nuevo valor
sera sobre escrito por la interrupción. 

*La solución de Bit-Banding*: El bit-banding resuelve este conflicto mapeando cada bit individual de una zona de memoria llamada *Bit-band Region* a una palabra completa de 32 bits en otra zona de memoria llamada *Alias Region*. Al escribir una palabra completa en la dirección de la zona alias, el hardware del microcontrolador traduce automáticamente esa escritura a una de lectura-modificación-escritura atómica en un único ciclo de bus sobre el bit correspondiente en la región original.

- *Escritura*: Si escribís un valor en una dirección del alias, solo el bit menos significativo (bit 0) del dato escrito determina el nuevo estado del bit real. Escribir un valor con el bit 0 en 1 (como 0x01 o 0xFF) pone el bit real en 1. Escribir un valor con el bit 0 en 0 (como 0x00 o 0x0E) pone el bit real en 0.
- *Lectura*: Al leer una palabra en la dirección del alias, el hardware devuelve 0x01 si el bit real está en 1, o 0x00 si el bit real está en 0. Los bits del 1 al 31 se retornan siempre como 0.

#figure(
  image("/images/bit-band.png", width: 50%)
)

#figure(
  image("/images/bit-band2.png", width: 50%)
) 

== Interrupciones

Una interrupción es un evento que suspende la 
ejecución normal del programa *forzando* al 
procesador a realizar otra 'tarea' de mayor 
prioridad que una vez finalizada retorna al 
programa suspendido.  



- Dicho evento es generado por el hardware y se lo  conoce como *Interrupt Request* (*`IRQ`*). Este pedido  es asincrónico al programa actualmente en ejecución.
-  La transferencia se realiza de manera automática.
-  La tarea es conocida como Interrupt Service Routine (*`ISR`*)

El programa en ejecución recibe de manera 
asíncrona el pedido de interrupción.
#text(fill: red,weight: "bold")[Dicha interrupción será aceptada al finalizar la 
instrucción actual de assembler (no de C)].
La latencia (tiempo de respuesta) del software es 
el tiempo que tarda desde que ocurre el evento 
hasta que el mismo es atendido.

=== Máscaras

Las interrupciones del procesador pueden ser inhibidas o 
habilitadas por software. La terminología frecuentemente 
usada es enmascarar (inhibir) una interrupción.
Existen dos tipos de máscaras.
- *Máscara global*: Una llave general que corresponde a un bit del procesador (Global Interrupt Enable).
- *Máscara individual*: Una llave o #text(fill: red,weight: "bold")[enable] para cada periferico del microcontrolador.

#figure(
  image("/images/int.png", width: 50%),
  caption: "Existen dos tipos de interrupciones: Enmascarables y no-enmascarables por software "
)

=== Interrupt Vectors

Un vector de interrupción es básicamente un puntero a una función. Es la dirección de memoria donde comienza el código de la rutina de servicio de interrupción (`ISR`), que es el programa que la CPU debe ejecutar cuando ocurre un evento de hardware específico.

La tabla de vectores de interrupción (`IVT`) es un arreglo o tabla en memoria donde se almacenan todos estos punteros de manera ordenada. Cuando se activa una interrupción, el hardware del procesador consulta esta tabla de forma automática para saber a qué dirección saltar

#figure(
  image("/images/vec.png", width: 50%)
)


=== Flags
Un periferico activa la interrupcion colocando un `1` en `D` y por lo tanto, `Q`.
`CPU` puede #text(fill: red,weight: "bold")[leer estado de flag], #text(fill: blue,weight: "bold")[resetear estado de flag] para terminar con la interrupcion

#figure(
  image("/images/flag.png", width: 50%)
)

=== Secuencia de la Interrupcion
Configuración inicial (*Software*)
+ Se habilita la interrupción particular (Periferico).
+ Se desenmascaran las interrupciones Globales.

Entrada a la rutina de interrupción (*Hardware*)
+ Se genera el pedido de interrupción, encendiéndose el flag correspondiente (xxxIF).
+ Se finaliza la ejecución de la instrucción en curso.
+ Se guarda en el stack el contexto de trabajo (dirección de retorno y demás registros) en forma automática.
+ Se transfiere el control a la `ISR`, mediante el vector de interrupción.

=== Codigo Bloqueante vs Pooling 

_Supongamos que un compañero va a pasar a visitarnos dentro de 
una o dos horas.
El momento exacto no lo sabe pero quedamos en que me enviara un 
mensaje por WhatsApp cuando este arribando a nuestra casa.
El problema es que mi celular se quedo sin audio después de 
finalizada la conversación así que no puedo saber en que momento 
me enviara el mensaje._ 

Posibles Soluciones 
 - Observar la pantalla hasta que aparezca el mensaje (esta solución  me impediría o bloquearía la posibilidad de realizar otras tareas )
 - Observar la pantalla del celular de vez cuando (esto resolvería el problema anterior permitiéndome intercalar otras tareas)

#text(fill: red,weight: "bold")[Código Bloqueante]: La CPU interroga constantemente al
periférico para ver si hay algún evento que atender. 

#text(fill: red,weight: "bold")[Pooling]: La CPU interroga al periférico intercalando ahora otras tareas

#figure(
  image("/images/pooling.png", width: 29%),
  caption: "Diagrama de Pooling"
)

Aunque resuelve el bloqueo total al permitir realizar más de una función, sigue siendo una estrategia ineficiente debido a que la CPU realiza consultas a una frecuencia extremadamente alta (en microsegundos) para eventos externos que ocurren muy lentamente (como un usuario pulsando un botón en el orden de los milisegundos).

=== Periodic Interrupt / Hardware Polling

Gran parte de los eventos generados por el hardware son lentos en
relación a la velocidad del procesador para este caso la mejor estrategia
es utilizar una interrupción periódica (`PISR`).

#figure(
  image("/images/perIn.png", width: 80%),
  caption: "Para interrupciones como un boton conviene tener un timer aparte de mas tiempo"
)

En lugar de consultar continuamente en el lazo principal, se configura un temporizador físico de hardware (como SysTick o un canal del módulo PIT) para que genere una interrupción a intervalos de tiempo fijos y controlados (por ejemplo, cada 10 milisegundos).

Al dispararse la interrupción periódica, la CPU suspende momentáneamente el programa principal, ejecuta una rutina de servicio rápida (ISR) donde realiza el chequeo del estado del periférico (hace el polling sincronizado por hardware), y regresa de inmediato al flujo principal.

Si el periférico no requiere atención, la rutina finaliza inmediatamente sin perturbar el procesamiento del lazo principal, reduciendo drásticamente la subutilización del chip.

#figure(
  image("/images/vs.png", width: 80%)
)


=== Interrupciones Dedicadas

Cuando el evento es de corta duración en 
relación al tiempo de la CPU una interrupción 
periódica no es posible. En estos casos 
deberemos utilizar una interrupción dedicada 
a ese evento.

#figure(
  image("/images/perr.png", width: 50%),
  caption: "Periodicas"
)

#figure(
  image("/images/perrDed.png", width: 50%),
  caption: "Perodicas + Dedicadas"
)

Comunicación entre el programa principal y la `ISR` con perifericos de entrada y salida.

#figure(
  image("/images/thread.png", width: 50%)
)

=== Fuentes de interrupción periódica
Todos los microcontroladores tienen un generador periódico de 
interrupciones. En general se los puede configurar por programa 
para modificar el periodo de interrupción

#figure(
  image("/images/fuentes.png", width: 70%)
)

#pagebreak()
== Interrupciones del K64

=== NVIC / Nested Vector Interrupt Controller
La arquitectura Cortex M4 tiene un control avanzado de 
interrupciones  y excepciones. El NVIC recibe excepciones del 
sistema así como interrupciones externas

#figure(
  image("/images/CMSIS.png", width: 40%),
  caption: "CMSIS: Cortex Microcontroller Software Interface Standard"
)

Es el controlador de interrupciones anidadas y vectorizadas integrado directamente dentro de la CPU Cortex-M4. A diferencia de otros sistemas de hardware donde el control de interrupciones es externo, el NVIC está fuertemente acoplado con la CPU. Esto permite tiempos de respuesta sumamente veloces y una integración optimizada con los modos de bajo consumo del microcontrolador.

#figure(
  image("/images/table.png", width: 50%),
  caption: "ARM CORE System Exceptions"
)

#figure(
  image("/images/table2.png", width: 50%),
  caption: "External System Exceptions"
)

Para controlar y supervisar las interrupciones de periféricos del K64, el NVIC utiliza un conjunto estructurado de registros agrupados en la estructura CMSIS `NVIC_Type`:

 - `ISER` (*Interrupt Set-Enable Registers*): Registros de 32 bits utilizados para habilitar individualmente cada línea de interrupción. El bit asignado en ISER a un periférico debe ponerse en 1 para que el procesador comience a escuchar ese evento.
- `ICER` (*Interrupt Clear-Enable Registers*): Registros para deshabilitar interrupciones específicas de forma individual.
- `ISPR` (*Interrupt Set-Pending Registers*): Registros que colocan una interrupción en estado pendiente. Esto permite disparar una interrupción por software de manera controlada para pruebas o programación estructurada.
- `ICPR` (*Interrupt Clear-Pending Registers*): Registros que limpian el estado pendiente de las interrupciones individuales.
- `IABR` (*Interrupt Active Bit Registers*): Registros que informan si una interrupción está activa en ese momento (ejecutando su respectivo Handler) o si ha sido pausada para atender a una de mayor prioridad.
- `IPR` o `IP` (*Interrupt Priority Registers*): Registros encargados de fijar la prioridad de cada interrupción. Aunque el procesador Cortex-M4 admite prioridades de 8 bits completos, el chip K64 solo implementa los 4 bits más significativos, permitiendo elegir entre 16 niveles de prioridad (#text(fill: red,weight: "bold")[donde 0 es la máxima prioridad y 15 es la mínima])

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`core_cm4.h`
```c
typedef struct
{
  __IOM uint32_t ISER[8U];               /*!< Offset: 0x000 (R/W)  Interrupt Set Enable Register */
        uint32_t RESERVED0[24U];
  __IOM uint32_t ICER[8U];               /*!< Offset: 0x080 (R/W)  Interrupt Clear Enable Register */
        uint32_t RSERVED1[24U];
  __IOM uint32_t ISPR[8U];               /*!< Offset: 0x100 (R/W)  Interrupt Set Pending Register */
        uint32_t RESERVED2[24U];
  __IOM uint32_t ICPR[8U];               /*!< Offset: 0x180 (R/W)  Interrupt Clear Pending Register */
        uint32_t RESERVED3[24U];
  __IOM uint32_t IABR[8U];               /*!< Offset: 0x200 (R/W)  Interrupt Active bit Register */
        uint32_t RESERVED4[56U];
  __IOM uint8_t  IP[240U];               /*!< Offset: 0x300 (R/W)  Interrupt Priority Register (8Bit wide) */
        uint32_t RESERVED5[644U];
  __OM  uint32_t STIR;                   /*!< Offset: 0xE00 ( /W)  Software Trigger Interrupt Register */
}  NVIC_Type;
```
]
=== Weak
El startup puede declarar handlers por defecto.
```c
void PORTA_IRQHandler(void) __attribute__((weak));
```

'Esta función existe como implementación por defecto, pero si el usuario proporciona otra con el mismo nombre, usá la del usuario.'

```c
void PORTA_IRQHandler(void)
{
    // MI código
}
```

=== CMSIS - Functions

Es una forma estandarizada de acceder al Cortex-M desde C para no necesitar calcular manualmente los registros todo el tiempo.

En vez de hacer:
```c
NVIC->ISER[1] = (1 << 26);
```
Podemos utiliazar 

```c
NVIC_EnableIRQ(PORTA_IRQn);
```

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`core_cm4.h`
```c
/* ##########################   NVIC functions  #################################### */
/**
  \ingroup  CMSIS_Core_FunctionInterface
  \defgroup CMSIS_Core_NVICFunctions NVIC Functions
  \brief    Functions that manage interrupts and exceptions via the NVIC.
  @{
 */
  #define NVIC_SetPriorityGrouping    __NVIC_SetPriorityGrouping
  #define NVIC_GetPriorityGrouping    __NVIC_GetPriorityGrouping
  #define NVIC_EnableIRQ              __NVIC_EnableIRQ
  #define NVIC_GetEnableIRQ           __NVIC_GetEnableIRQ
  #define NVIC_DisableIRQ             __NVIC_DisableIRQ
  #define NVIC_GetPendingIRQ          __NVIC_GetPendingIRQ
  #define NVIC_SetPendingIRQ          __NVIC_SetPendingIRQ
  #define NVIC_ClearPendingIRQ        __NVIC_ClearPendingIRQ
  #define NVIC_GetActive              __NVIC_GetActive
  #define NVIC_SetPriority            __NVIC_SetPriority
  #define NVIC_GetPriority            __NVIC_GetPriority
  #define NVIC_SystemReset            __NVIC_SystemReset
```
]

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`core_cm4.h`
```c
/**
  \brief   Set Interrupt Priority
  \details Sets the priority of a device specific interrupt or a processor exception.
           The interrupt number can be positive to specify a device specific interrupt,
           or negative to specify a processor exception.
  \param [in]      IRQn  Interrupt number.
  \param [in]  priority  Priority to set.
  \note    The priority cannot be set for every processor exception.
 */
__STATIC_INLINE void __NVIC_SetPriority(IRQn_Type IRQn, uint32_t priority)
{
  if ((int32_t)(IRQn) >= 0)
  {
    NVIC->IP[((uint32_t)IRQn)]               = (uint8_t)((priority << (8U - __NVIC_PRIO_BITS)) & (uint32_t)0xFFUL);
  }
  else
  {
    SCB->SHP[(((uint32_t)IRQn) & 0xFUL)-4UL] = (uint8_t)((priority << (8U - __NVIC_PRIO_BITS)) & (uint32_t)0xFFUL);
  }
}
```
]

=== Ejemplo de Implementacion de Interrupcion


#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`App.c`
```c
__ISR__ SW3_Handler (void){
	PORT_ClearInterruptFlag (PA, 4);
  gpioToggle(PIN_LED_BLUE);
}
```

```c
/* Función que se llama 1 vez, al comienzo del programa */
void App_Init (void){
	hw_DisableInterrupts(); //para que no me interrumpan la inicializacion

	//Habilito los clocks de solo los puertos que voy a usar
	SIM->SCGC5 |= SIM_SCGC5_PORTB_MASK;
	SIM->SCGC5 |= SIM_SCGC5_PORTA_MASK;
	SIM->SCGC5 |= SIM_SCGC5_PORTE_MASK;

	//LED VERDE
	PORTE->PCR[26]=0x0; 					                //Clear all bits
	PORTE->PCR[26]|=PORT_PCR_MUX(1); 		          //Set MUX to GPIO that is ALT1 
	PORTE->PCR[26]|=PORT_PCR_DSE(1);          		//Drive strength enable

  // Global Pin Control High Registe Which Pins. Me ahorro:
  // PORTB->PCR[21] = ...
  // PORTB->PCR[22] = ...
	uint32_t temp = PORT_GPCHR_GPWE((1<<(21-16))|(1<<(22-16))); 
	temp|=PORT_GPCHR_GPWD(PORT_PCR_MUX(1));  //Set MUX to GPIO

	// Now set pins  output properties
	temp|=PORT_GPCHR_GPWD(PORT_PCR_DSE(1));			  //Drive strength enable
	PORTB->GPCHR=temp;								            //Set all at once

	//SW3 - Pin: PTA4
	PORTA->PCR[4]=0x0;                 //Clear
	PORTA->PCR[4]|=PORT_PCR_MUX(1); 	 //Set MUX to GPIO
	PORTA->PCR[4]|=PORT_PCR_PE(1);     //Pull UP/Down  Enable
	PORTA->PCR[4]|=PORT_PCR_PS(1);     //Pull UP
	// Enable interrupt on this pin (PTA4)
	PORTA->PCR[4]|=PORT_PCR_IRQC(PORT_eInterruptRising);     //Enable Rising edge interrupts

	// Nos aseguramos de que todo arranque apagado
	gpioWrite(PIN_LED_RED, !LED_ACTIVE);
	gpioWrite(PIN_LED_BLUE, !LED_ACTIVE);

	gpioWrite(PIN_LED_GREEN, LED_ACTIVE);
	SysTick_Init();
	hw_EnableInterrupts();		
}
```
]


#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`SysTick.c`

```c
// Puntero a función (callback) para ejecutar la rutina del usuario
static void (*p_callback)(void) = 0;
```
```c
/* Inicializa el SysTick para generar ticks periódicos y guarda el callback */
void SysTick_Init(void (*func)(void))
{
    // 1. Guardar la función que se llamará en cada interrupción
    p_callback = func;
    // 2. Deshabilitar el temporizador antes de configurar
    SysTick->CTRL = 0x00;
    // 3. Cargar el valor de cuenta para 125 ms @ 100 MHz (12,500,000 ciclos - 1)
    SysTick->LOAD = 12500000L - 1;
    // 4. Limpiar el valor actual del contador
    SysTick->VAL = 0x00;
    // 5. Configurar fuente de reloj del núcleo, habilitar interrupción y activar SysTick
    SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk |
                    SysTick_CTRL_TICKINT_Msk  |
                    SysTick_CTRL_ENABLE_Msk;
}
```

```c
/* ISR nativa del procesador para SysTick */
void SysTick_Handler(void)
{
    // Ejecutar el callback del usuario si fue registrado en Init
    if (p_callback != 0)
    {
        p_callback();
    }
}
```
]
#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`gpio.h`
```c
// Ports
enum { PA, PB, PC, PD, PE };

// Convert port and number into pin ID
// Ex: PTB5  -> PORTNUM2PIN(PB,5)  -> 0x25
//     PTC22 -> PORTNUM2PIN(PC,22) -> 0x56
#define PORTNUM2PIN(p,n)    (((p)<<5) + (n))
#define PIN2PORT(p)         (((p)>>5) & 0x07)
#define PIN2NUM(p)          ((p) & 0x1F)
```
]

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`gpio.c`

```c
//Escribe un valor HIGH o LOW en un pin digital
void gpioWrite (pin_t pin, bool value){
    uint8_t portId = PIN2PORT(pin);
    uint8_t pinNum = PIN2NUM(pin);

    if (value) {gpio_ptrs[portId]->PSOR = (1 << pinNum);} // Port Set Output Register
      else {gpio_ptrs[portId]->PCOR = (1 << pinNum);}     // Port Clear Output Register   
}
```
```c
// Invierte el valor de un pin digital (HIGH<->LOW)
void gpioToggle (pin_t pin){
    uint8_t portId = PIN2PORT(pin);
    uint8_t pinNum = PIN2NUM(pin);

    gpio_ptrs[portId]->PTOR = (1 << pinNum); // Port Toggle Output Register
}
```

```c
//Lee el valor de un pin digital especificado
bool gpioRead (pin_t pin)
{
    uint8_t portId = PIN2PORT(pin);
    uint8_t pinNum = PIN2NUM(pin);
    
    return (gpio_ptrs[portId]->PDIR & (1 << pinNum)) != 0; // Port Data Input Register
}
```
```c
//Inicializa como interrupcion al pin, con el modo y hacia la func handler que le mandes. - IRQ
bool gpioIRQ(pin_t pin, uint8_t irqMode, pinIrqFun_t irqFun) {
	uint8_t portId = PIN2PORT(pin);
  uint8_t pinNum = PIN2NUM(pin);

  if (portId > PE || irqMode >= GPIO_IRQ_CANT_MODES) {return false;}
  
  irq_callbacks[portId][pinNum] = irqFun;

  static const uint8_t irqc_map[] = {0x0, 0x9, 0xA, 0xB};
  
  uint32_t irqc_value = irqc_map[irqMode]; // Obtenemos el valor directo sin switch

  static PORT_Type * const puertos_base[] = {PORTA, PORTB, PORTC, PORTD, PORTE};

  puertos_base[portId]->PCR[pinNum] = (puertos_base[portId]->PCR[pinNum] & ~PORT_PCR_IRQC_MASK) | 
                                      PORT_PCR_IRQC(irqc_value);

  //Se para en la posicion base del primer puerto y se mueve port id veces hasta tu puerto
  NVIC_EnableIRQ(PORTA_IRQn + portId); 

  return true;
}
```
]