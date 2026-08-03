= Guía de Ejercicios N.º 1 

Contestar las siguientes preguntas, indicando en cuál documento y sección se encuentra la respuesta:

== Aprendiendo a leer la documentación del MCU MK64FN1M0VLL12


#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[

1. ¿En cuál número de pin del MCU se encuentra el puerto `PTA12`?
2. ¿Cuáles pines pueden funcionar como entradas analógicas?
3. ¿Cuántos pines del puerto `PTE` se encuentran efectivamente disponibles en este modelo de MCU?
4. ¿Cuál es el rango de valores de tensión para detectar un 0 y un 1 lógico en un pin I/O? ¿Se puede enviar 5 V a un pin?
5. ¿Cuánta es la máxima corriente que entrega un pin I/O?

]

==  Verificando toolchain Kinetis
#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[


- Abrir e importar al MCUXpresso IDE el proyecto de ejemplo *Blink*.
- Compilar y verificar que la compilación se complete correctamente.
- Descargar el programa al MCU mediante el debugger; ejecutar y comprobar que parpadea el LED de la placa.
- Colocar un breakpoint y ejecutar paso a paso. Visualizar la variable `veces` y el código en assembler del ciclo `while`; ejecutar instrucción por instrucción.
- Modificar el nivel de optimización a «Optimize most». ¿Cambia el comportamiento del programa? Investigar qué cambia y por qué.
]

== 3 Editando el funcionamiento de Blink

#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[

- Modificar el programa para que titile el LED verde a 0.5 Hz (1 segundo encendido, 1 segundo apagado).
- Obtener una captura de osciloscopio del pin del LED.
]


== Proyecto Pul2Switch

#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[

- Basado en *Blink*, crear un nuevo proyecto llamado *Pul2Switch*.
- Modificar el programa para que el LED cambie de estado en cada pulsación del pulsador SW3 (es decir, por flanco).
- ¿El LED cambia de estado siempre que se presiona el pulsador? Si no, investigar por qué (rebote, configuración de pull-ups, lógica inversa, etc.).
- Modificar el programa para usar el pulsador SW2 deshabilitando el pull-up por software. ¿Sigue funcionando? Investigar por qué.
]


== Interfaciando con la FRDM-K64F
#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[
- Conectar la FRDM-K64F a un protoboard para usar un pulsador externo y un LED amarillo externo. Colocar el pulsador en `PTC9` y el LED en `PTB23`.
- Usar una resistencia de 330 Ω en serie con el LED y una resistencia de 330 Ω en serie con el pulsador para evitar cortocircuitos.
- Modificar el programa para el nuevo conexionado y verificar depurando paso a paso.
- Luego mover el pulsador a `PTC0` y el LED a `PTA0`; adaptar el programa y verificar.
]


== Proyecto Baliza

#box(
  stroke: 1pt,
  inset: 18pt,
  radius: 10pt,
)[
- Crear un proyecto nuevo llamado *Baliza* que simule la baliza de un automóvil.
- Al pulsar SW3, el LED amarillo externo debe parpadear a 0.5 Hz. Al volver a pulsar, debe apagarse. El LED rojo de la placa debe indicar cuando la baliza está activada.
- Asegurarse de que el programa no pierda eventos de pulsado del pulsador (manejo de rebote y detección por flancos).
]

