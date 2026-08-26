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

