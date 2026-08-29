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

