= Clase 3

== Prioridad de Interrupciones

1. *Tail-Chaining*
Al terminar de ejecutar una rutina de servicio de interrupción (ISR), si existe otra interrupción pendiente con la prioridad suficiente para ser atendida, el procesador evita realizar la secuencia completa de desapilado de registros (pop) y posterior apilado (push)

En lugar de desperdiciar ciclos de reloj restaurando el contexto para luego volver a guardarlo, la CPU salta directamente a la ejecución del nuevo manejador pendiente

Gracias a esto, la transición entre interrupciones consecutivas demora únicamente 6 ciclos de reloj en condiciones de memoria sin estados de espera, en comparación con los más de 20 ciclos que requeriría hacer el desapilado y apilado completo

#figure(
  image("/images/tail.png", width: 50%),
  caption: "Interrupt Latency - Tail Chaining"
)

2. *Pre-Emption*
Para que ocurra el desalojo, la nueva interrupción entrante debe tener una prioridad de grupo estrictamente mayor (es decir, un número de prioridad menor en el registro de configuración) que la interrupción que se está ejecutando

Si la nueva interrupción tiene una prioridad de grupo igual o menor, no se produce el desalojo; la nueva interrupción simplemente permanece en estado pendiente hasta que el procesador finalice la ejecución del manejador actual

Cuando se produce el desalojo, las interrupciones se anidan, y el procesador guarda automáticamente el contexto en la pila para retomar la tarea suspendida de forma segura más tarde

#figure(
  image("/images/pre.png", width: 50%),
  caption: "Interrupt Latency - Pre-Emption"
)

3. *Late Arrival*
Si una interrupción de alta prioridad se activa durante la fase en la que el procesador está realizando el apilado automático de registros para una interrupción previa de menor prioridad, el hardware no detiene ni descarta el proceso de apilado

Como el estado que debe guardarse en la pila es idéntico sin importar cuál de las dos interrupciones se ejecute primero, el apilado de registros continúa sin verse afectado

Sin embargo, en paralelo a esa acción, el procesador cambia la búsqueda del vector en la tabla y salta directamente a ejecutar primero la rutina de la interrupción de mayor prioridad (la que llegó tarde)

El hardware permite aceptar esta interrupción de llegada tardía hasta antes de que la primera instrucción del manejador original de menor prioridad entre en la etapa de ejecución de la CPU

#figure(
  image("/images/late.png", width: 50%),
  caption: "Interrupt Latency - Late Arrival"
)


