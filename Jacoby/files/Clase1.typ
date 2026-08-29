= Clase 1

== Buses de datos y de direcciones

#figure(
  image("/images/dataBus.png", width: 100%)
) <fig:dataBus>

Con una instrucción como `LDAA $1000`, la CPU solicita el contenido de la dirección de memoria `$1000` y lo carga en el acumulador `A`. La dirección viaja por el *Address Bus* y el dato leído vuelve por el *Data Bus*.

El *Address Bus* indica *con qué dispositivo* se quiere comunicar la CPU y el *Data Bus* transporta *qué valor* se lee o se escribe. Ambos buses trabajan coordinadamente durante cada acceso a memoria.

Para evitar que varios periféricos intenten conducir el *Data Bus* al mismo tiempo, sus salidas utilizan buffers *tri-state*. La lógica de control habilita un único dispositivo durante la transferencia:
- `R/W` indica si la operación es de lectura (*Read*) o escritura (*Write*).
- `CS` (*Chip Select*) habilita el periférico seleccionado.
- Un dispositivo no seleccionado desconecta eléctricamente su salida del bus y queda en *alta impedancia* (`Z`).

#box(
  stroke: 1pt,
  inset: 10pt,
  radius: 5pt
)[
*Baja impedancia:* el circuito está conectado al bus y puede imponer un nivel lógico.

*Alta impedancia (`Z`):* el circuito se comporta como si estuviera desconectado del bus.
]

El `Address Bus` llega a la *lógica de decodificación* (`LC`), una lógica combinacional que observa la dirección y genera señales de selección. Según el rango de direcciones, activa el `CS` del periférico correspondiente.

Por ejemplo, si las direcciones `$1000` a `$2000` están asignadas a la RAM, una dirección dentro de ese rango activa `CS_RAM`. La CPU no “habla” directamente con todos los periféricos: la decodificación determina cuál puede responder.

La asignación de rangos y la lógica de decodificación forman parte del diseño del `MCU`.

#figure(
  image("/images/ej.png", width: 60%)
) <fig:addressDecode>


== GPIO: entradas y salidas digitales

#figure(
  image("/images/gpioIn.png", width: 70%)
) <fig:gpioIn>


Los pines de un GPIO se controlan mediante registros mapeados en memoria. Cada registro tiene una dirección propia, por lo que la CPU puede acceder a él usando el mismo mecanismo de buses explicado anteriormente.

En este ejemplo, `P1DIR` determina la dirección de cada pin: un bit en `0` configura el pin como entrada y un bit en `1` lo configura como salida. El circuito se repite para cada bit del puerto.

#figure(
  image("/images/gpio.png", width: 70%),
  caption: "Ejemplo Generico"
) <fig:gpio>

=== Readback: leer el estado de una salida

El *readback* es una técnica para verificar el estado de una señal usando un pin de lectura. Se configura un pin como `OUTPUT`, que genera la señal, y otro como `INPUT`, que la observa.

Esto resulta útil para detectar si una salida realmente cambia de estado o si existe una falla en el circuito externo. Los dos pines deben estar conectados correctamente y nunca se deben configurar dos salidas con valores opuestos sobre el mismo conductor.

#figure(
  image("/images/readBack.png", width: 70%),
) <fig:readBack>

=== Active-low y active-high

#figure(
  image("/images/active.png", width: 70%),
) <fig:active>

Una señal es *active-high* cuando se considera activa en nivel lógico `1`. Es *active-low* cuando se considera activa en nivel lógico `0`; suele indicarse con una barra superior, un sufijo `_n` o una burbuja en el esquema.

Por ejemplo, un `LED_EN_n` habilita el LED cuando vale `0`. El nivel lógico y el significado funcional no siempre coinciden: `0` puede significar “activo”.

=== Propiedades eléctricas de un pin

#figure(
  image("/images/pin.png", width: 50%),
) <fig:pin>

Los pines suelen incluir diodos de protección. Estos comienzan a conducir cuando la tensión supera aproximadamente $V_"DD"$ o cae por debajo de $V_"SS"$ (según el circuito del microcontrolador). No deben utilizarse como fuente normal de protección: hay que respetar los límites eléctricos del *datasheet*.

También se puede configurar una resistencia interna `PULL-UP` o `PULL-DOWN`. Su función es evitar que una entrada quede *flotante* cuando ningún circuito externo fija su nivel lógico.

Es posible configurar por software los pines como `INPUT` o `OUTPUT`, pero esa configuración debe coincidir con el circuito conectado. Para observar la diferencia con un osciloscopio, una salida presenta baja impedancia y domina el nivel del pin. Una entrada presenta alta impedancia y puede captar ruido; al acercar un dedo puede observarse una señal de red de aproximadamente $50 "Hz"$.

Si una señal externa está fuera del rango permitido del pin, no alcanza con configurarla como entrada. Es necesario adaptar la tensión, por ejemplo con un divisor resistivo y, cuando corresponda, diodos o un circuito de protección dimensionado para la aplicación.

#figure(
  image("/images/prot.png", width: 50%),
) <fig:prot>


*Drive strength (`DSE`):* es la capacidad de corriente de la salida. Define qué carga puede manejar el pin a una velocidad determinada sin degradar la integridad de la señal.

Una mayor capacidad de manejo no siempre es mejor: puede aumentar el consumo y el ruido electromagnético. Se debe elegir la configuración mínima que cumpla con los tiempos y la carga requeridos.

=== Configuraciones de pines con MOSFETS

#figure(
  image("/images/logica.png", width: 100%),
  caption: "Implementación de lógica digital con MOSFET y elevación de la tensión de salida"
) <fig:logica>


== GPIO del K64

El K64 contiene cinco puertos GPIO de 32 bits cada uno. No todos los pines necesariamente están disponibles en el encapsulado o cumplen la función GPIO, por lo que siempre hay que consultar el *datasheet*.
- `PORTA` `[31:0]`
- `PORTB` `[31:0]`
- `PORTC` `[31:0]`
- `PORTD` `[31:0]`
- `PORTE` `[31:0]`

#figure(
  image("/images/pcrMap.png", width: 80%),
  caption: "Kinetis K64 - Reference Manual - Chapter 4"
) 

Cada puerto dispone de registros de datos de 32 bits. La `X` representa el puerto elegido (`A`, `B`, `C`, `D` o `E`):
- `GPIOX_PDOR` (*Port Data Output Register*): valor que se envía a los pines configurados como salida.
- `GPIOX_PSOR` (*Port Set Output Register*): escribe `1` en los bits indicados del `PDOR`.
- `GPIOX_PCOR` (*Port Clear Output Register*): escribe `0` en los bits indicados del `PDOR`.
- `GPIOX_PTOR` (*Port Toggle Output Register*): invierte los bits indicados del `PDOR`.
- `GPIOX_PDIR` (*Port Data Input Register*): permite leer el nivel observado en los pines.
- `GPIOX_PDDR` (*Port Data Direction Register*): `0` configura entrada y `1` configura salida.

Los registros `PSOR`, `PCOR` y `PTOR` permiten modificar bits sin hacer una operación de lectura-modificación-escritura sobre `PDOR`. Esto es especialmente útil cuando una interrupción u otra parte del programa también puede acceder al puerto.

#figure(
  image("/images/gen.png", width: 100%),
  caption: "Registros de datos de un puerto GPIO"
)
=== PDDR
#figure(
  image("/images/PDDR.png", width: 80%),
  caption: "Configuración de dirección mediante PDDR"
) 

=== PSOR
#figure(
  image("/images/PSOR.png", width: 80%),
  caption: "Puesta en uno de bits mediante PSOR"
) 

=== PCOR
#figure(
  image("/images/PCOR.png", width: 80%),
  caption: "Puesta en cero de bits mediante PCOR"
) 

=== PTOR
#figure(
  image("/images/PTOR.png", width: 80%),
  caption: "Conmutación de bits mediante PTOR"
) 

=== PDIR
#figure(
  image("/images/PDIR.png", width: 80%),
  caption: "Lectura de entradas mediante PDIR"
) 


== PCR: configuración individual de cada pin

Cada pin de cada puerto se configura mediante un registro de 32 bits llamado *Pin Control Register* (`PCR`). Este registro pertenece a la capa `PORT`, mientras que los registros `PDOR`, `PDIR` y relacionados pertenecen a la capa `GPIO`.

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`PORTX_PCRn`

donde `X` puede ser `A`, `B`, `C`, `D` o `E`, y `n` puede tomar valores de `0` a `31`.

Los campos más importantes del `PCR` son:
- `MUX`: selecciona la función del pin. Para usarlo como GPIO se debe elegir la alternativa indicada por el *Reference Manual* (en el K64 suele ser `ALT1`).

- `w1c`: Se escribe un 1 para limpiar el bit
- `IRQC`: Determina que tipo de flanco genera la interrupcion. (`0000` no reacciona a nada)
- `LK`: Determina si los bits del `PCR` [0:15] puedan ser o no modificados
- `DSE`: Selecciona la capacidad de corriente de la salida.
- `SRE`: Controla la velocidad de transición (*slew rate*).
#figure(
  image("/images/sre.png", width: 50%)
) 
- `PE` y `PS`: Habilitan y seleccionan la resistencia interna de *pull-up* o *pull-down*.


#figure(
  image("/images/pcr.png", width: 100%),
  caption: "Campos del PCR"
) 

Algo a tener en cuenta, es que los campos en gris indican que los bits no son accesibles.

]

=== PCR - MUX

#figure(
  image("/images/mux2.png", width: 100%)
) 

#figure(
  image("/images/k64f.png", width: 100%),
  caption: "Kinetis K64F Sub-Family Data
Sheet - Pin Out"
) 






=== Secuencia para configurar un pin como GPIO

Una secuencia típica de inicialización es:
1. Habilitar el reloj del puerto en `SIM->SCGC5`.
2. Configurar `PORTX_PCRn` con el `MUX` correspondiente y las características eléctricas necesarias.
3. Definir la dirección en `GPIOX_PDDR`: `0` para entrada o `1` para salida.
4. Escribir o leer el estado mediante `PDOR`, `PSOR`, `PCOR`, `PTOR` o `PDIR`.

El orden es importante: un registro del periférico no puede utilizarse correctamente si su reloj no fue habilitado previamente.

== PCR - Global

#figure(
  image("/images/glob.png", width: 90%)
) 

Global Pin Control *Low* Register: `PORTx_GPCLR`
#figure(
  image("/images/low.png", width: 50%)
) 
Global Pin Control *High* Register: `PORTx_GPCHR`
#figure(
  image("/images/high.png", width: 50%)
)
=== Interrupt Status Flag Register (PORTx_ISFR)

El registro `PORTx_ISFR` (Interrupt Status Flag Register) es una herramienta de hardware que facilita la identificación de qué pin generó una interrupción dentro de un puerto específico.


== Digital Filter

El filtrado de las entradas digitales permite rechazar pulsos no deseados
presentes en líneas digitales que normalmente están en 0 o 1.
Estas interferencias pueden provenir de fuentes de RF y/o conmutadores
electromecánicos, etc.

#figure(
  image("/images/dig.png", width: 70%)
) 

#figure(
  image("/images/dig2.png", width: 70%)
) 

== Clock Gating

- Los procesadores modernos poseen mecanismos para reducir el consumo del chip apagando todos los recursos que no son usados. Esto se logra apagando el clock de dichos módulos (clock gating).
- Para configurar que módulos reciben clock se deben habilitar los bits correspondientes en los registros SCGCx (System Clock Gating Control Register x).
- Después del reset estos bits están apagados para ahorrar energía.
- Los SCGCx. se encuentran dentro del modulo SIM (System Integration Module).
- Antes de usar un modulo se debe habilitar el clock de lo contrario se genera un error. De igual forma antes de apagar un clock se deberá deshabilitar el modulo.

#figure(
  image("/images/gate.png", width: 70%)
) 

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`MK64F12.h`
```c
/*! @name SCGC5 - System Clock Gating Control Register 5 */
#define SIM_SCGC5_LPTMR_MASK                     (0x1U)
#define SIM_SCGC5_LPTMR_SHIFT                    (0U)
...
#define SIM_SCGC5_PORTA_MASK                     (0x200U)
#define SIM_SCGC5_PORTA_SHIFT                    (9U)
...
#define SIM_SCGC5_PORTB_MASK                     (0x400U)
#define SIM_SCGC5_PORTB_SHIFT                    (10U)
...
#define SIM_SCGC5_PORTC_MASK                     (0x800U)
#define SIM_SCGC5_PORTC_SHIFT                    (11U)
...
```
]


== Proramming PORTx_ISFR

Antes de trabajar con cualquier `GPIO`:
+  *GATING* Enable clock for used ports
+  *PORT* Configure MUX & PIN
+  *GPIO* Configure I/O


#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`MK64F12.h`
```c
#define __I volatile const
#define __O volatile
#define __IO volatile
GPIO Peripheral Access Layer
/** GPIO - Register Layout Typedef */
typedef struct {
__IO uint32_t PDOR; /**< Port Data Output Register, offset: 0x0 */
__O uint32_t PSOR; /**< Port Set Output Register, offset: 0x4 */
__O uint32_t PCOR; /**< Port Clear Output Register, offset: 0x8 */
__O uint32_t PTOR; /**< Port Toggle Output Register, offset: 0xC */
__I uint32_t PDIR; /**< Port Data Input Register, offset: 0x10 */
__IO uint32_t PDDR; /**< Port Data Direction Register, offset: 0x14 */
} GPIO_Type ;
```


]


Ejemplo de Clock-Gating:
```c
//Enable clocking for port B
SIM->SCGC5 |= SIM_SCGC5PORTB_MASK

PTB->PCOR = (1<<21)|(1<<22); // Clear pin 21 and 22
PTB->PSOR = (1<<21)|(1<<22); // Set pin 21 and 22
PTB->PDOR = (PTB->PDOR & ~(1<<pin)) | (data << pin); // Change pin value
PTB->PDDR = (1<<21)|(1<<22); // Defino pin 21 y 22 del GPIO B como Salidas
PTB->PTOR = (1<<21)|(1<<22); // Toggle pin 21 and 22

if (PTA->PDIR & (1<<4)) // Test pin 4
  Do_something(); // if pin 4 == 1

```
== PORT_type

#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`MK64F12.h`
```c
/** PORT Peripheral Access Layer
/** PORT - Register Layout Typedef */
typedef struct {
__IO uint32_t PCR[32]; /**< Pin Control Register n, array offset: 0x0, array step: 0x4 */
__O uint32_t GPCLR; /**< Global Pin Control Low Register, offset: 0x80 */
__O uint32_t GPCHR; /**< Global Pin Control High Register, offset: 0x84 */
uint8_t RESERVED_0[24];
__IO uint32_t ISFR; /**< Interrupt Status Flag Register, offset: 0xA0 */
uint8_t RESERVED_1[28];
__IO uint32_t DFER; /**< Digital Filter Enable Register, offset: 0xC0 */
__IO uint32_t DFCR; /**< Digital Filter Clock Register, offset: 0xC4 */
__IO uint32_t DFWR; /**< Digital Filter Width Register, offset: 0xC8 */
} PORT_Type;


```
]