= Guía de Ejercicios N.º 2

Contestar las siguientes preguntas, indicando en cuál documento y sección se encuentra la respuesta:

== Aprendiendo a leer el Reference Manual del K64

1. ¿Cuál es la dirección absoluta donde se encuentra el registro PCR del pin `PTA12`?


2. ¿Cuál bit del registro PCR corresponde al *Interrupt Status Flag*?


3. Luego del *reset* los pines del puerto `B`: ¿cómo tienen configurada su dirección (entrada o salida)? ¿Y cómo tienen configurado el *slew-rate* (activado o no)? ¿Y cómo tienen configurado el *pull* (desactivado, activado *pullup* o activado *pulldown*)?


== Aprendiendo a leer el SDK

1. Analizar la estructura `Port_Type`. ¿En cuál archivo se encuentra declarado? ¿Por qué tiene campos reservados?


== MyBlink

1. Basado en Blink, crear un proyecto nuevo llamado `MyBlink`.


2. Quitar el archivo `gpio.o` y escribir su propio archivo `gpio.c`, de tal forma que se implementen las funciones (servicios) de `gpio.h`.


3. Verificar el correcto funcionamiento de `gpio.c` en los proyectos `Pul2Switch` y `Baliza`.


== SysTick

1. Escribir su propio archivo `SysTick.c`, de tal forma que se implementen las funciones (servicios) de `SysTick.h`.


2. Modificar el proyecto `MyBlink` para que el retardo se implemente con el SysTick en lugar de un ciclo. Analizar cómo hacer para que el retardo no sea bloqueante. Verificar el correcto funcionamiento con un osciloscopio.


3. Agregar un pin de testeo (*tespoint* o TP) que se encienda mientras se ejecuta la interrupción. Medir el tiempo que dura la ISR y cuánto representa porcentualmente.


== Baliza_SysTick

1. Basado en los proyectos anteriores, crear el proyecto `Baliza_SysTick` que implemente el programa de la baliza utilizando SysTick como base de tiempo. Utilizar el pulsador SW3 y realizar un muestreo periódico de su estado para detectar eventos.


== Interrupciones de puerto

1. Escribir un nuevo archivo `gpio.c`, de tal forma que se implementen las funciones (servicios) de manejo de interrupciones del nuevo `gpio.h`.


2. Escribir un programa de prueba (*testbench*) que verifique el correcto funcionamiento de la nueva implementación de `gpio`.


3. Agregar un TP que se encienda mientras se ejecuta la interrupción. Medir el tiempo que dura la ISR.


== Baliza_IRQ

1. Basado en los proyectos anteriores, crear el proyecto `Baliza_IRQ` que implemente el programa de la baliza utilizando el nuevo gpio para leer el pulsador. Utilizar el pulsador SW2 y detectar evento de presionado por interrupción.

