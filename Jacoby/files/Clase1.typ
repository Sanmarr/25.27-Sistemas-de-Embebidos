= Clase 1

== DataBus/DataAddress

#figure(
  image("/images/dataBus.png", width: 100%)
) <fig:dataBus>

Con `LDAA $1000` cargo el contenido de la direccion de memoria al adder `A` en la `CPU` a traves del `DataBus`.

Para impedir que los perifericos se superpongan, se utilizan buffers a traves *READ* and *WRITE* (`R/W`). Estos R/W se encuentran para cada periferico determinando si se encutran en funcionamiento o no.

#box(
  stroke: 1pt,
  inset: 10pt,
  radius: 5pt
)[
*Baja impedancia* = 1

*Alta impedancia* = 0
]

El `AddressBus` tiene informacion de con quien voy a hablar, en este caso con la posicion `$1000` de memoria. El `AddressBus` se conecta a *Logica de Decodificacion Debugeable (`LC`)*  que es una logica combinacional  que son una serie de salidas. Cuando el `AddressBus` se encuentra en cierto *rango* se activan *ciertas* salidas. Las salidas se llaman `ChipSelect` o tambien conocido como `FLASH`. Por ejemplo, en caso de que la informacion del `AddressBus` se encuentre entre `$1000-$2000` viniendo de la `RAM`, se activa el $"CS"_"RAM"$ (Chip Select de la RAM).

La *Logica de Decodificacion Debugeable (`LC`)* la diseña uno cuando diseña un `MCU`.

#figure(
  image("/images/ej.png", width: 60%)
) <fig:dataBus>


== GPIO

#figure(
  image("/images/gpioIn.png", width: 70%)
) <fig:gpioIn>


Para que el `AdressBus` pueda diferenciar los diferentes registros del GPIO, estos tienen diferentes posiciones de memoria. Cada Regustrto tendra su propio `ChipSelect`.

En este ejemplo, `P1DIR` determina si el pin se encuentra leyendo o escribiendo un dato. Pensar que en la imagen se replica por cada bit.

#figure(
  image("/images/gpio.png", width: 70%),
  caption: "Ejemplo Generico"
) <fig:gpio>

=== Readback

Es uan tecnica para poder leer el estado de un pin utilizando otro. Para esto, uno de ellos se lo declara `OUTPUT` y el otro `INPUT`.

#figure(
  image("/images/readBack.png", width: 70%),
) <fig:readBack>

=== ActiveLow/ActiveHigh

#figure(
  image("/images/active.png", width: 70%),
) <fig:active>

=== Propiedades de un pin

#figure(
  image("/images/pin.png", width: 50%),
) <fig:pin>

Cuentan con diodos en caso de errar con las tensiones comenzando a conducir (Por encima de $V_"DD"$ y debajo de $V_"EE"$). Ademas, puedo configurar una resistencia de `PULL-DOWN` o `PULL-UP`.

Puedo pifiar con software configurando `INPUTS` y `OUTPUTS`.
Una forma de detectar si el pin es entrada o salida, es colocar la punta del osciloscopio y acercar un dedo. Si esta configurado como `OUTPUT`, no se deberia ver nada al presentar una *baja* impedancia mientras que de estar configurada como `INPUT` se deberia observar una senoidal inducida de $50 "Hz"$ al presentar un *alta* impedancia.

En el caso de tener entradas al pin mayores o por debajo del rango del pin, en necesario aplicar un divisor resistivo y un para de diodos en caso de que falle la conexion del divisor resistivo.

#figure(
  image("/images/prot.png", width: 50%),
) <fig:prot>


*Drive Strength:*  Es la máxima corriente que puede entregar el pin a la carga.
Por lo tanto el DS fija la máxima carga que se puede poner para una velocidad 
dada sin afectar la integridad de la señal. 

=== Configuraciones de pines con MOSFETS

#figure(
  image("/images/logica.png", width: 100%),
  caption: "Como implementar logica digital con MOSFETS y como elevar la tensiones de salida"
) <fig:logica>


== GPIO del K64

GPIO contiene 5 Puertos de 32 bits c/u
 + PORTA `[31:0]`
 + PORTB `[31:0]`
 + PORTC `[31:0]`
 + PORTD `[31:0]`
 + PORTE `[31:0]`

 - Port Data Output Register (GPIOX_PDOR) `[31:0]`
 - Port Set Output Register (GPIOX_PSOR) `[31:0]`
 - Port Clear Output Register (GPIOX_PCOR) `[31:0]`
 - Port Toggle Output Register (GPIOX_PTOR) `[31:0]`
 - Port Data Input Register (GPIOX_PDIR) `[31:0]`
 - Port Data Direction Register (GPIOX_PDDR) `[31:0]`

#figure(
  image("/images/gen.png", width: 100%)
) 
=== PDDR
#figure(
  image("/images/PDDR.png", width: 80%)
) 

=== PSOR
#figure(
  image("/images/PSOR.png", width: 80%)
) 

=== PCOR
#figure(
  image("/images/PCOR.png", width: 80%)
) 

=== PTOR
#figure(
  image("/images/PTOR.png", width: 80%)
) 

=== PDIR 
#figure(
  image("/images/PDIR.png", width: 80%)
) 


== PCR
Cada pin de cada puerto es configurable mediante un registro de 32 
bits llamado *Pin Control Register* (`PCR`)
#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
PORTX_PCRn

donde X=A,B,C,D,E  n=0:31

#figure(
  image("/images/pcr.png", width: 100%),
  caption: "Algo confuso, existen w1c que indican que se debe escribir un 1 para colocar un 0 en el bit deseado."
) 

]



#figure(
  image("/images/pcrMap.png", width: 100%),
  caption: "Ejemplo de PCR para el puerto A"
) 






#box(
  stroke: 0.5pt,
  inset: 10pt,
  radius: 0pt
)[
`gpio.c`
```c
int variableValida;
int _contador;
int valor2;
```
]

