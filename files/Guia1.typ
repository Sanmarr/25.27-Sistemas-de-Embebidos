= Guía de Ejercicios N.º 1 

Contestar las siguientes preguntas, indicando en cuál documento y sección se encuentra la respuesta:

== Aprendiendo a leer la documentación del MCU MK64FN1M0VLL12


#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
1. ¿En cuál número de pin del MCU se encuentra el puerto PTA12?  #sym.ballot.check.heavy
]



Dado que estamos utilizando la placa de evaluación FRDM-K64F, el encapsulado es el de 100 LQPF, por lo que segun la documentacion corresponde al pin 42.

#figure(
  image("/images/100LQPF.png", width: 100%)
)

#figure(
  image("/images/PTA12.png", width: 100%),
  caption: "Kinetis K64F Sub-Family Data-Sheet, PinOut"
)

#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
2. ¿Cuáles pines pueden funcionar como entradas analógicas?
]
\
+ Pines *analógicos dedicados* y de *alta resolución*:
 - Pin 14: ADC0_DP1
 - Pin 15: ADC0_DM1
 - Pin 16: ADC1_DP1
 - Pin 17: ADC1_DM1
 - Pin 18: ADC0_DP0 / ADC1_DP3
 - Pin 19: ADC0_DM0 / ADC1_DM3
 - Pin 20: ADC1_DP0 / ADC0_DP3
 - Pin 21: ADC1_DM0 / ADC0_DM3
+ Pines del *Puerto A*:
 - PTA7 (Pin 59): ADC0_SE10
 - PTA8 (Pin 60): ADC0_SE11
 - PTA12 (Pin 42): CMP2_IN0
 - PTA13 (Pin 43): CMP2_IN1
 - PTA17 (Pin 47): ADC1_SE17
+  Pines del *Puerto B*:
 - PTB0 (Pin 53): ADC0_SE8 y ADC1_SE8
 - PTB1 (Pin 54): ADC0_SE9 y ADC1_SE9
 - PTB2 (Pin 55): ADC0_SE12
 - PTB3 (Pin 56): ADC0_SE13
 - PTB10 (Pin 58): ADC1_SE14
 - PTB11 (Pin 59): ADC1_SE15
+ Pines del *Puerto C*:
 - PTC2 (Pin 72): ADC0_SE4b y CMP1_IN0
 - PTC3 (Pin 73): CMP1_IN1
 - PTC6 (Pin 78): CMP0_IN0
+ Pines del *Puerto E*:
 - PTE1 (Pin 2): ADC1_SE5a
 - PTE2 (Pin 3): ADC0_DP2 y ADC1_SE6a
 - PTE3 (Pin 4): ADC0_DM2 y ADC1_SE7a
 - PTE24 (Pin 31): ADC0_SE17
 - PTE25 (Pin 32): ADC0_SE18
+ Otros pines con funciones *analógicas especiales*:
 - Pin 26 (VREF_OUT): ADC1_SE18, CMP1_IN5 y CMP0_IN5
 - Pin 27 (DAC0_OUT): ADC0_SE23 y CMP1_IN3

#figure(
  image("/images/pinout.jpg", width: 100%)
)

#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
3. ¿Cuántos pines del puerto `PTE` se encuentran efectivamente disponibles en este modelo de MCU?
]

En el microcontrolador MK64FN1M0VLL12 con encapsulado 100 LQFP, se encuentran efectivamente disponibles 10 pines del puerto PTE.

#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
4. ¿Cuál es el rango de valores de tensión para detectar un 0 y un 1 lógico en un pin I/O? ¿Se puede enviar 5 V a un pin?
]

Segun la hoja de datos en la seccion 3.6.1.1, dado que la tensión de alimentacion se debe encontrar entrar enrtre $1.71 V$ y $3.6 V$, segun la hoja de datos:


$
  (V_H)_"max" = 3.6V \
  (V_H)_"min" = 1.13V\
  (V_L)_"min" = (V_L)_"max" = V_"SSA" = "GND"
$



#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
5. ¿Cuánta es la máxima corriente que entrega un pin I/O?
]

==  Verificando toolchain Kinetis


#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
1. Abrir e importar al MCUXpresso IDE el proyecto de ejemplo `Blink`.
]

#box(
  fill: rgb("#f58888"),
  inset: 10pt,
  radius: 5pt
)[
2. Compilar y verificar que la compilación se complete correctamente.
]

3. Descargar el programa al MCU mediante el debugger; ejecutar y comprobar que parpadea el LED de la placa.

4. Colocar un breakpoint y ejecutar paso a paso. Visualizar la variable `veces` y el código en assembler del ciclo `while`; ejecutar instrucción por instrucción.



5. Modificar el nivel de optimización a 'Optimize most'. ¿Cambia el comportamiento del programa? Investigar qué cambia y por qué.


== Editando el funcionamiento de Blink



1. Modificar el programa para que titile el LED verde a 0.5 Hz (1 segundo encendido, 1 segundo apagado).


2. Obtener una captura de osciloscopio del pin del LED.

== Proyecto Pul2Switch



1. Basado en Blink, crear un nuevo proyecto llamado Pul2Switch.

2. Modificar el programa para que el LED cambie de estado en cada pulsación del pulsador SW3 (es decir, por flanco).

3. ¿El LED cambia de estado siempre que se presiona el pulsador? Si no, investigar por qué (rebote, configuración de pull-ups, lógica inversa, etc.).

4. Modificar el programa para usar el pulsador SW2 deshabilitando el pull-up por software. ¿Sigue funcionando? Investigar por qué.



== Interfaciando con la FRDM-K64F

1. Conectar la FRDM-K64F a un protoboard para usar un pulsador externo y un LED amarillo externo. Colocar el pulsador en `PTC9` y el LED en `PTB23`.

2. Usar una resistencia de 330 Ω en serie con el LED y una resistencia de 330 Ω en serie con el pulsador para evitar cortocircuitos.

3. Modificar el programa para el nuevo conexionado y verificar depurando paso a paso.

4. Luego mover el pulsador a `PTC0` y el LED a `PTA0`; adaptar el programa y verificar.



== Proyecto Baliza

1. Crear un proyecto nuevo llamado Baliza que simule la baliza de un automóvil.

2. Al pulsar SW3, el LED amarillo externo debe parpadear a 0.5 Hz. Al volver a pulsar, debe apagarse. El LED rojo de la placa debe indicar cuando la baliza está activada.

3. Asegurarse de que el programa no pierda eventos de pulsado del pulsador (manejo de rebote y detección por flancos).



