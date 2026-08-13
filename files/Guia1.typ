= Guía de Ejercicios N.º 1 

Contestar las siguientes preguntas, indicando en cuál documento y sección se encuentra la respuesta:

== Aprendiendo a leer la documentación del MCU MK64FN1M0VLL12



1. ¿En cuál número de pin del MCU se encuentra el puerto PTA12?

#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[

Dado que estamos utilizando la placa de evaluación FRDM-K64F, el encapsulado es el de 100 LQPF, por lo que segun la documentacion corresponde al pin 42.

]


2. ¿Cuáles pines pueden funcionar como entradas analógicas?
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
#figure(
  image("/images/pinout.jpg", width: 80%)
)


3. ¿Cuántos pines del puerto `PTE` se encuentran efectivamente disponibles en este modelo de MCU?

#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]

4. ¿Cuál es el rango de valores de tensión para detectar un 0 y un 1 lógico en un pin I/O? ¿Se puede enviar 5 V a un pin?
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
Segun la hoja de datos en la seccion 3.6.1.1, dado que la tensión de alimentacion se debe encontrar entrar enrtre $1.71 V$ y $3.6 V$, segun la hoja de datos:


$
  (V_H)_"max" = 3.6V \
  (V_H)_"min" = 1.13V\
  (V_L)_"min" = (V_L)_"max" = V_"SSA" = "GND"
$


]

5. ¿Cuánta es la máxima corriente que entrega un pin I/O?
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]

==  Verificando toolchain Kinetis



1. Abrir e importar al MCUXpresso IDE el proyecto de ejemplo `Blink`.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]

2. Compilar y verificar que la compilación se complete correctamente.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
3. Descargar el programa al MCU mediante el debugger; ejecutar y comprobar que parpadea el LED de la placa.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
4. Colocar un breakpoint y ejecutar paso a paso. Visualizar la variable `veces` y el código en assembler del ciclo `while`; ejecutar instrucción por instrucción.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]


5. Modificar el nivel de optimización a 'Optimize most'. ¿Cambia el comportamiento del programa? Investigar qué cambia y por qué.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]

== Editando el funcionamiento de Blink



1. Modificar el programa para que titile el LED verde a 0.5 Hz (1 segundo encendido, 1 segundo apagado).
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]

2. Obtener una captura de osciloscopio del pin del LED.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[

]
== Proyecto Pul2Switch



1. Basado en Blink, crear un nuevo proyecto llamado Pul2Switch.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
2. Modificar el programa para que el LED cambie de estado en cada pulsación del pulsador SW3 (es decir, por flanco).
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
3. ¿El LED cambia de estado siempre que se presiona el pulsador? Si no, investigar por qué (rebote, configuración de pull-ups, lógica inversa, etc.).
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[
#sym.ballot.check.heavy
]
4. Modificar el programa para usar el pulsador SW2 deshabilitando el pull-up por software. ¿Sigue funcionando? Investigar por qué.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[

]


== Interfaciando con la FRDM-K64F

1. Conectar la FRDM-K64F a un protoboard para usar un pulsador externo y un LED amarillo externo. Colocar el pulsador en `PTC9` y el LED en `PTB23`.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
2. Usar una resistencia de 330 Ω en serie con el LED y una resistencia de 330 Ω en serie con el pulsador para evitar cortocircuitos.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
3. Modificar el programa para el nuevo conexionado y verificar depurando paso a paso.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
4. Luego mover el pulsador a `PTC0` y el LED a `PTA0`; adaptar el programa y verificar.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]


== Proyecto Baliza

#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[
1. Crear un proyecto nuevo llamado Baliza que simule la baliza de un automóvil.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
2. Al pulsar SW3, el LED amarillo externo debe parpadear a 0.5 Hz. Al volver a pulsar, debe apagarse. El LED rojo de la placa debe indicar cuando la baliza está activada.
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
3. Asegurarse de que el programa no pierda eventos de pulsado del pulsador (manejo de rebote y detección por flancos).
#box(
  fill: rgb("#90EE90"),
  inset: 10pt,
)[



]
]

