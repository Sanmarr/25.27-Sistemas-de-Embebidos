// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo: [Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
  [
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo: [Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
  [
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo: [¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
  [
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo: [Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
  [
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let imagen(desc) = figure(
  rect(width: 100%, height: 6cm, fill: rgb("#f0f0f0"), stroke: 1pt + gray)[
    #align(center + horizon)[#text(fill: gray)[🖼️ #desc]]
  ]
)

// ==========================================
// CLASE 11
// ==========================================

= Clase 11

== RTOS: Real-Time Operating Systems

#cuadro-concepto(titulo: [Objetivo de la clase])[
Hasta ahora programamos con un *superloop* más interrupciones. Cuando la aplicación crece, ese esquema ya no puede *garantizar* que cada tarea cumpla sus *deadlines*. La solución es un *RTOS*: un sistema operativo mínimo que ejecuta varias *tareas* "en paralelo" y siempre le da la CPU a la de *mayor prioridad*. En esta clase vemos (1) qué significa _tiempo real_, (2) por qué falla el superloop, (3) cómo funcionan el *scheduler* y el *context switch*, (4) cómo se protegen los *recursos compartidos* (mutex, semáforos, colas) y (5) cómo se usa un RTOS (µC/OS-III) para armar una aplicación y un driver.
]

=== Tiempo real

*Tiempo real (RT)* es una clasificación referida al *tiempo de reacción a eventos*. Un sistema RT debe cumplir con *deadlines* (plazos máximos).

Una operación RT es *correcta* si se cumplen *las dos* condiciones:

+ El *resultado* es correcto.
+ El resultado se obtuvo *dentro del tiempo correcto*.

#cuadro-atencion(titulo: [Rápido no es lo mismo que tiempo real])[
Tiempo real *no* significa "muy rápido", sino *"a tiempo, siempre"*: lo importante es la *garantía* de cumplir el deadline, no la velocidad promedio.
]

#table(
  columns: (1fr, 2.2fr, 1.6fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Tipo*], [*Característica*], [*Ejemplos*]),
  [*No tiempo real*], [No hay deadlines. La reacción a un evento ocurrirá en el futuro, pero *sin garantías* de cuándo.], [Compilador, navegador web, E-reader.],
  [*Soft real-time*], [*Mayor tolerancia* a perder deadlines. Perderlos no es tan crítico, pero *degrada el rendimiento*.], [Videollamadas, videojuegos.],
  [*Hard real-time*], [*Muy baja tolerancia* a perder deadlines. Perderlos puede ser *catastrófico*, incluso *letal* para un ser humano.], [Marcapasos, ciertos procesos industriales, impresoras.],
)

#cuadro-atencion(titulo: [Hard RT absoluto])[
Diseñar sistemas *hard RT absolutos* (cero tolerancia) es *muy difícil* y se debe hacer con *extremo cuidado*.
]

=== Linux embebido vs. RTOS

Los sistemas embebidos se pueden encarar de dos maneras muy distintas:

#table(
  columns: (1fr, 1.6fr, 1.6fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([], [*GNU/Linux embebido*], [*RTOS*]),
  [*Para qué*], [Sistemas embebidos *complejos*.], [Optimizar la *ejecución en tiempo real*.],
  [*Cómo es*], [Versiones de GNU/Linux similares al Linux de escritorio (buscar: *Yocto Project*).], [*Minimalista*: puede correr en micros con *menos recursos*.],
  [*Programas*], [Se ejecutan en *user space*; los drivers de HW viven en el *kernel*.], [La aplicación es *monolítica*: se ejecuta directo sobre el HW (*bare-metal*).],
)

=== Superloop (foreground/background)

Es el esquema que veníamos usando: un *loop infinito* (*background*) que ejecuta las tareas una tras otra, y las *ISR* (*foreground*) que interrumpen el loop cuando ocurre un evento y avisan al background (por ejemplo, con un flag).

//#imagen([Superloop: Task 1 a Task 4 en el loop infinito (background) e ISR / ISR anidada (foreground); diapositiva 7])

#figure(
  align(image("/images/2P/superloop.png", width: 60%)),
  caption: [Task 1 a Task 4 en el loop infinito (background) e ISR / ISR anidada (foreground)]
)


#text(fill: green)[*Ventajas:*]

- Es *simple de programar*.
- El background es un simple loop esperando eventos generados por ISR.
- Requiere *un único stack*.

#text(fill: red)[*Desventaja de fondo:*] para aplicaciones más complejas es difícil representar todo como una *FSM*.

==== ¿Qué problema tiene este paradigma para tiempo real?

- El *tiempo de reacción* de cada tarea puede ser tan grande como la *suma de las otras tareas* (hay que esperar a que termine toda la vuelta del loop).
- El tiempo de las otras tareas puede ser *no determinístico*.
- Cada vez que se *modifica o agrega* una tarea, hay que *garantizar de nuevo* que el tiempo máximo del loop sea menor a *cada* deadline.

#cuadro-ejemplo(titulo: [Ejemplo: el cocinero con una sola mano])[
Imaginá un cocinero que revisa en orden: la sopa, el horno, la pizza y la plancha, y recién después vuelve a la sopa. Si la tarea de "freír" tarda mucho, la sopa se pasa de punto aunque sea urgente. Ese es el superloop: *nadie puede interrumpir a una tarea larga*, y la tarea urgente tiene que esperar su turno.
]

==== Posibles soluciones (y por qué no alcanzan)

#table(
  columns: (1.5fr, 2.5fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Solución*], [*Problema*]),
  [Mover operaciones urgentes *adentro de las ISR*.], [*Empeora el tiempo de reacción* del resto del sistema.],
  [Ejecutar las tareas RT *más frecuentemente* dentro del loop.], [Es *difícil de mantener* y *no garantiza* RT.],
  [*Partir las tareas largas* no-RT en pedacitos para no "atorar" el sistema.], [Es *inmantenible* y no siempre se puede.],
)

#cuadro-concepto(titulo: [Conclusión])[
Necesitamos un sistema *multi-tasking*.
]

=== Multi-tasking

- *Multi-tasking* es la idea de ejecutar tareas en *paralelo*.
- Una *tarea* es una secuencia de operaciones definida, típicamente implementada como una *función*.
- Una *aplicación* se descompone en un conjunto de tareas: algunas se ejecutan *en serie* y otras *en paralelo*.
- Las tareas usualmente necesitan *compartir información* entre ellas.

El multi-tasking es un ejemplo de *virtualización*, ya que hay *más tareas que CPUs*:

- Cada tarea "*cree*" que es la única y que tiene la CPU solo para ella.
- El RTOS contiene un *scheduler* que elige *cuándo ejecutar cada tarea* y crea esa ilusión.
- El scheduler garantiza que *en cada momento la CPU esté ejecutando la tarea de mayor prioridad*.

=== Scheduling

*¿Cómo decide el scheduler cuándo le da la CPU a cada tarea?* La idea inicial es *round-robin*: se reparte la CPU por turnos, tan rápido que parece que todas se ejecutan a la vez, pero *en cada instante solo una tarea corre*.

//#imagen([Round-robin: todas las tareas "parecen" ejecutarse, pero solo una corre en cada instante; diapositiva 13])

#figure(
  align(image("/images/2P/RoundRobin.png", width: 70%)),
  caption: [Round-robin: todas las tareas "parecen" ejecutarse, pero solo una corre en cada instante]
)

Para lograrlo se usa un *timer* (por ejemplo, *SysTick*) que genera *ticks* periódicos: en cada tick se *interrumpe la tarea*, se cede el control al scheduler y se *retorna a una tarea diferente*.

//#imagen([Threads de igual prioridad alternándose con una ISR periódica (tick); diapositiva 14])

#figure(
  align(image("/images/2P/scheduling.png", width: 60%)),
  caption: [
  Threads de igual prioridad alternándose con una ISR periódica (tick)
  ]
)

Este esquema simple presenta #text(fill: red,weight: "bold")[tres problemas], y cada uno se resuelve agregando una idea al scheduler:

==== #text(fill: red,weight: "bold")[Problema 1:] No todas las tareas necesitan ejecutarse siempre

Por ejemplo, una tarea que está esperando a que se presione un botón no tiene nada para hacer hasta que eso pase. *Solución:* el RTOS asigna *estados* a cada tarea. Los más importantes:

#table(
  columns: (1fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Estado*], [*Significado*]),
  [`running`], [Está usando la CPU. *Solo 1 tarea* puede tener este estado.],
  [`ready`], [Lista para ejecutarse, pero *todavía no tiene el control* de la CPU.],
  [`suspended`], [Está *esperando un evento*; no necesita ejecutarse todavía.],
)

El scheduler round-robin *solo ejecuta tareas en estado `ready`*.

==== #text(fill: red,weight: "bold")[Problema 2:] Tiene que correr siempre la de máxima prioridad

*Solución:* el scheduler no usa una simple FIFO, sino *priority scheduling*:

- La cola de tareas `ready` se *ordena por prioridad*: las más altas se insertan *delante* de las más bajas.
- Las de *igual prioridad* preservan el orden en que fueron insertadas (FIFO).
- Una tarea de menor prioridad debe esperar a que *todas* las tareas de prioridad superior pasen a `suspended` para poder ejecutarse.

==== #text(fill: red,weight: "bold")[Problema 3:] ¿Qué pasa si ninguna tarea está `ready`?

Todas están esperando eventos. *Solución:* el RTOS define una tarea por defecto llamada *IDLE* que... *no hace nada*. Tiene la *prioridad más baja posible*, así que solo corre cuando no hay nada mejor para hacer.

#cuadro-concepto(titulo: [Resumen del scheduler])[
*Round-robin con prioridades:* solo se consideran tareas `ready`, siempre corre la de mayor prioridad, las de igual prioridad se turnan en cada tick, y si no hay ninguna lista corre *IDLE*.
]

=== Context switch

Con round-robin, luego de cada *tick* el RTOS cambia la tarea. *¿Cómo hace el RTOS para pasar de una tarea a otra?*

Para pasar a una tarea diferente, el scheduler debe *restaurar exactamente el estado que tenía la CPU* la última vez que se ejecutó esa tarea. Este proceso se llama *context switch* e incluye restaurar:

- Los *valores de los registros* de la CPU.
- `PC`, `LR`, `SP`, etc.
- El *contenido del stack*: *cada tarea debe tener su propio stack* con un tamaño máximo.

//#imagen([Estado de la CPU (R0 a R12, SP, LR, PC, PSR) y la RAM con el espacio de cada tarea: variables de housekeeping, copia de los registros y stack propio; diapositiva 19])

#figure(
  align(image("/images/2P/context-switch.png", width: 100%)),
  caption: [
  Estado de la CPU (R0 a R12, SP, LR, PC, PSR) y la RAM con el espacio de cada tarea: variables de housekeeping, copia de los registros y stack propio
  ]
)

En la RAM, cada tarea tiene reservado un bloque con: unas *variables de "housekeeping"* (las que el RTOS necesita para administrarla), *espacio para guardar una copia de los registros* de la CPU, y su *propio stack*. El resto de la RAM queda para variables globales y heap.

El context switch se hace en cuatro pasos:

+ *Guardar:* el scheduler guarda el estado de los registros de la tarea que se va a pausar (copia de la CPU hacia el bloque de esa tarea).

+ *Restaurar registros:* el scheduler restaura el estado de los registros de la tarea que se va a resumir (de su bloque hacia la CPU).

+ *Restaurar el stack pointer:* se carga el `SP` de la nueva tarea, para que use *su propio stack*.

+ *Restaurar el PC:* el último paso siempre es restaurar el `PC`; a partir de ahí la CPU *continúa ejecutando la nueva tarea* justo donde la había dejado.

#figure(
  align(image("/images/2P/CONTEXT.png", width: 115%))
)

//#imagen([Pasos 1 y 2: guardar registros de la tarea saliente y restaurar los de la entrante; diapositivas 20 y 21])

//#imagen([Pasos 3 y 4: restaurar SP y PC, la CPU continúa con la Tarea 2; diapositivas 22 y 23])

#cuadro-atencion(titulo: [Por qué el PC va al final])[
Apenas se carga el `PC`, la CPU *ya está ejecutando la nueva tarea*. Por eso todo lo demás (registros y `SP`) tiene que estar restaurado *antes*.
]

==== ¿Cuándo pasa una tarea al estado suspendido?

El RTOS ofrece *múltiples funciones que suspenden una tarea*. Para la tarea la función es "bloqueante", pero en realidad *se ejecutan otras tareas* mientras tanto.

```c
void tarea1() {
    inicializar_tarea1(); //loop infinito

    while (true) {
        RTOS_esperar_boton();           // espera a que una ISR active un flag
        prender_led();

        RTOS_esperar_tiempo_ms(1000);   // espera un intervalo de tiempo
        apagar_led();
    }
}
```

- `RTOS_esperar_boton()`: espera a que se active un *flag desde una ISR*.
- `RTOS_esperar_tiempo_ms(1000)`: espera un *intervalo de tiempo*. El RTOS implementa sus *propios timers*.

==== ¿Cuándo hay context switch?

Hasta ahora lo mencionamos en el *tick* del scheduler, pero además:

- Cuando una tarea *se suspende*, se aprovecha para hacer un context switch.
- Cuando *termina una interrupción*, se puede hacer un context switch (por ejemplo, si la ISR dejó `ready` a una tarea de mayor prioridad, se ejecuta *inmediatamente*).

//#imagen([Una ISR deja ready a un thread de alta prioridad y este se ejecuta enseguida; diapositiva 25])

#figure(
  align(image("/images/2P/threadPrior.png", width: 60%)),
  caption: [Una ISR deja ready a un thread de alta prioridad y este se ejecuta enseguida]
)


=== Scheduler preemptivo vs. cooperativo

#table(
  columns: (1fr, 2fr, 2fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([], [*Preemptivo (anticipativo)*], [*Cooperativo*]),
  [*Quién decide el cambio*], [El *scheduler* le puede quitar la CPU a una tarea *sin su conocimiento*, por tick o ISR.], [La *tarea* es la única que decide ceder el control, cuando *se auto-suspende*.],
  [*Ventajas*], [*Mejor tiempo de respuesta*: la tarea de mayor prioridad corre apenas está lista.], [*Más simple* diseñar la sincronización entre tareas; ayuda a *evitar condiciones de carrera*.],
  [*Desventajas*], [Hay que proteger los recursos compartidos (ver más adelante).], [*Peor tiempo de respuesta*.],
)

//#imagen([Scheduler cooperativo: la ISR deja ready al thread de alta prioridad, pero este no corre hasta que el de baja prioridad hace yield(); diapositiva 27])

#figure(
  align(image("/images/2P/cooperativo.png", 
  width: 60%)),
  caption: [Scheduler cooperativo: la ISR deja ready al thread de alta prioridad, pero este no corre hasta que el de baja prioridad hace yield()]
)

En un scheduler cooperativo, la ISR pone al thread de alta prioridad en la lista `ready`, pero *no se ejecuta hasta que el thread de baja prioridad ceda la CPU* (`yield()`). Si esa tarea tarda, la de alta prioridad espera.

=== Estados de una tarea en µC/OS-III

El RTOS que usamos en la materia es *µC/OS-III*. Sus estados son un poco más detallados que los tres que vimos:

#table(
  columns: (1fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Estado*], [*Descripción*]),
  [`Dormant`], [La tarea existe pero *todavía no fue creada* en el RTOS (o su función `task()` *terminó*).],
  [`Ready`], [Lista para correr; espera su turno de CPU.],
  [`Running`], [Está *ejecutándose* en la CPU.],
  [`Pending`], [*Esperando un evento* (o un timeout). Es el equivalente al `suspended` visto antes.],
  [`Interrupted`], [La CPU está atendiendo una *IRQ*.],
)

//#imagen([Diagrama de estados de una tarea en µC/OS-III; diapositiva 28])

#figure(
  align(image("/images/2P/run.png", width: 70%)),
  caption: [Diagrama de estados de una tarea en µC/OS-III]
)

*Transiciones:*

#table(
  columns: (1.3fr, 1fr, 2.2fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Transición*], [*Disparador*], [*Qué pasa*]),
  [`Dormant` → `Ready`], [`OSTaskCreate()`], [Se crea la tarea y queda lista para ejecutarse.],
  [`Ready` ⇄ `Running`], [*Context switch*], [El scheduler elige la tarea de mayor prioridad y la pone a correr; la que corría vuelve a `Ready`.],
  [`Running` → `Pending`], [Esperar evento], [La tarea llama a una función bloqueante (semáforo, mutex, cola, delay...).],
  [`Pending` → `Ready` / `Running`], [Evento o timeout], [Ocurrió lo que esperaba (o venció el tiempo): vuelve a estar lista y, si corresponde, corre.],
  [`Running` → `Interrupted`], [`IRQ`], [Entra una interrupción.],
  [`Interrupted` → `Running`], [`IRQ return` (sin context switch)], [Termina la ISR y sigue la misma tarea.],
  [`Interrupted` → `Ready`], [`IRQ return` + context switch (*preemption*)], [Termina la ISR pero hay una tarea de mayor prioridad lista: la tarea interrumpida queda en `Ready`.],
  [`Running` → `Dormant`], [La función `task()` termina], [La tarea finaliza.],
)

=== Cómo se crea una tarea en µC/OS-III

```c
static OS_TCB  myTaskTCB;          // Task Control Block (struct) usado para "housekeeping"
static CPU_STK myTaskStack[128];   // Área reservada para el stack

static void myTask(void *arg)
{
    while (1) {
        LED_ON();
        OSTimeDly(500);            // suspende la tarea por 500 ms
        LED_OFF();
        OSTimeDly(500);
    }
}

int main(void)
{
    OSTaskCreate(&myTaskTCB, "LED", myTask, NULL, 5, myTaskStack, 0, 128, ... );
    ...
    OSStart(NULL);                 // inicia la ejecución del sistema
}
```

#table(
  columns: (1.3fr, 3fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Elemento*], [*Qué es*]),
  [`OS_TCB`], [*Task Control Block*: struct que usa el RTOS para el "housekeeping" de la tarea (estado, prioridad, `SP` guardado, etc.).],
  [`CPU_STK myTaskStack[128]`], [Área de memoria reservada para el *stack propio* de la tarea.],
  [`myTask`], [Puntero a la *función* de la tarea. Es un loop infinito que se suspende con funciones bloqueantes.],
  [`NULL`], [*Argumento* opcional que recibe la función.],
  [`5`], [*Prioridad* de la tarea.],
  [`128`], [*Tamaño del stack*.],
  [`OSStart(NULL)`], [*Inicia la ejecución* del sistema: a partir de acá manda el scheduler.],
)

#cuadro-atencion(titulo: [Sobre OSTimeDly])[
`OSTimeDly(500)` cuenta en *ticks* del RTOS. Con un tick de 1 ms equivale a los 500 ms que indica el comentario.
]

=== Recursos compartidos

Cuando hay *múltiples threads o IRQs* compartiendo recursos, aparecen *problemas de sincronización*. Los recursos pueden ser, por ejemplo:

- *Zonas de memoria compartida* para intercambiar información entre threads.
- *Variables compartidas* entre un thread y una IRQ.
- Un *periférico* (por ej. la UART) usado por más de un thread.

==== Exclusión mutua

La *exclusión mutua* en recursos compartidos asegura que *mientras yo estoy usando el recurso, otro thread no lo puede usar*. Si quiero usar un recurso ocupado, tengo que *esperar a que se libere*: "formo fila" detrás del recurso (aunque el thread de más prioridad se me va a colar).

#cuadro-atencion(titulo: [Usar un OS NO hace seguro el acceso])[
Es *responsabilidad del programador* identificar y proteger los recursos compartidos. El RTOS solo ofrece las herramientas.
]

==== Ejemplos de lo que puede salir mal


*Ejemplo 1: un thread calcula y comparte el resultado con otro.*

```c
typedef struct {
    float x; float y; float z;
} position_t;

position_t current_position;

void ThreadGPS(void) {
    while (1) {
        readGPS();  //Se encuentra actualizando la posicion del GPS mientras dispara
        current_position = GetPosition();
    }
}
void ThreadMainApplication(void) {
    while (1) {
        useCurrentPositionForSomething(current_position);
    }
}
```

*Problema:* las variables `x`, `y`, `z` podrían *actualizarse parcialmente*. Si `ThreadMainApplication` lee justo a la mitad de la escritura, obtiene una posición "mezcla" (por ejemplo, `x` nueva pero `y` y `z` viejas) que nunca existió realmente.


*Ejemplo 2: dos threads quieren enviar mensajes por la UART.*

```c
void Thread1(void) {
    while (1) { writeStringToUART("HOLA"); }
}
void Thread2(void) {
    while (1) { writeStringToUART("chau"); }
}
void writeStringToUART(const char *str) {
    while (*str) {
        while (UART->IF & UART_IF_TDRE);
        UART->DR = *str++;
    }
}
```

*Problema:* los mensajes se *intercalan* carácter a carácter y por la UART sale algo como `HcOhLaAu`, en vez de `HOLA` y `chau` completos.

*Ejemplo 3: un thread y un driver se comunican mediante un buffer circular.*

```c
void Thread(void) {
    while (1) { int c = pop(&cb); }
}
void UART_ISR(void) {
    if (UART0->S & RDRF) { push(&cb, UART0->D); }
}
```

*Problema:* `push` hace `cb->n++` y `pop` hace `cb->n--` sobre la *misma variable*. En assembler, cada una es una secuencia *leer (`ldr`) → modificar (`add`/`sub`) → escribir (`str`)*. Si la ISR interrumpe al thread *en el medio* de esa secuencia, uno de los dos cambios se *pierde* y el contador `n` queda mal. Es una *condición de carrera*.

==== Condición de carrera (race condition)

Una *condición de carrera* ocurre cuando el resultado depende del *orden en que se intercalan* las ejecuciones de dos threads. Ejemplo: dos threads incrementan el mismo entero que vale 0.

#grid(
  columns: (1fr, 1fr),
  gutter: 14pt,
  [
    *Orden "bueno" → resultado 2*

    #table(
      columns: (1.3fr, 1.3fr, 0.8fr),
      inset: 5pt,
      stroke: 0.5pt + luma(180),
      align: center,
      table.header([*Thread 1*], [*Thread 2*], [*Valor*]),
      [], [], [0],
      [read value], [], [0],
      [increase value], [], [0],
      [write back], [], [1],
      [], [read value], [1],
      [], [increase value], [1],
      [], [write back], [2],
    )
  ],
  [
    *Orden "malo" → resultado 1*

    #table(
      columns: (1.3fr, 1.3fr, 0.8fr),
      inset: 5pt,
      stroke: 0.5pt + luma(180),
      align: center,
      table.header([*Thread 1*], [*Thread 2*], [*Valor*]),
      [], [], [0],
      [read value], [], [0],
      [], [read value], [0],
      [increase value], [], [0],
      [], [increase value], [0],
      [write back], [], [1],
      [], [write back], [1],
    )
  ],
)

En el caso malo ambos leen `0`, ambos calculan `1` y ambos escriben `1`: *se perdió un incremento*. Lo peor es que el bug es *intermitente*: solo aparece cuando el cambio de contexto cae en el momento justo.

#cuadro-concepto(titulo: [Sección crítica])[
La *sección crítica* es el tramo de código que accede al recurso compartido (leer-modificar-escribir). Hay que garantizar que *nadie más* acceda al recurso mientras se ejecuta.
]

==== Alternativa 1: Zonas críticas (deshabilitar interrupciones)

```c
void ThreadGPS(void) {
    while (1) {
        readGPS();
        ENTER_CRITICAL();                       // deshabilita interrupciones globales
        current_position = GetPosition();
        EXIT_CRITICAL();                        // habilita interrupciones globales
    }
}
void ThreadMainApplication(void) {
    while (1) {
        ...
        ENTER_CRITICAL();
        useCurrentPositionForSomething(current_position);
        EXIT_CRITICAL();
        ...
    }
}
```

- Habilitar y deshabilitar interrupciones es *extremadamente rápido* (`CPSID`, `CPSIE` = *1 ciclo*).
- *Efecto colateral:* aumenta la *latencia del sistema* (¡grave!), porque mientras las IRQ están deshabilitadas, el sistema no puede reaccionar a nada (tampoco al tick del scheduler).
- Hacerlo *solo cuando el tiempo con IRQ deshabilitadas es muy corto*.

==== Alternativa 2: Mutex

```c
MUTEX_T position_mutex;

void ThreadGPS(void) {
    while (1) {
        readGPS();
        MUTEX_LOCK(&position_mutex);
        current_position = GetPosition();
        MUTEX_UNLOCK(&position_mutex);
    }
}
void ThreadMainApplication(void) {
    while (1) {
        ...
        MUTEX_LOCK(&position_mutex);
        useCurrentPositionForSomething(current_position);
        MUTEX_UNLOCK(&position_mutex);
        ...
    }
}
```

- `MUTEX_LOCK` *toma el control* del recurso compartido.
- Si el recurso *ya está en uso*, el thread *se suspende* (y corren otras tareas).
- *No se deshabilitan interrupciones.*
- *Garantiza* que no haya condiciones de carrera.

#cuadro-atencion(titulo: [¿Se puede hacer un LOCK dentro de una ISR?])[
*¡No!* Una ISR no puede suspenderse: si el mutex estuviera ocupado, *bloquearía la ISR* (y con ella a todo el sistema). Para compartir datos con una ISR se usa otra herramienta (ver semáforos y colas).
]

#table(
  columns: (1fr, 1.6fr, 1.6fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([], [*Zona crítica*], [*Mutex*]),
  [*Cómo funciona*], [Deshabilita las interrupciones globales.], [El thread se suspende si el recurso está ocupado.],
  [*Costo*], [Casi nulo, pero *aumenta la latencia* de todo el sistema.], [Mayor que deshabilitar IRQ, pero el resto del sistema sigue respondiendo.],
  [*Cuándo usarlo*], [Solo si la sección es *muy corta*.], [Secciones más largas; recursos como un periférico.],
  [*Desde una ISR*], [Se puede (es justo lo que protege contra ella).], [*No se puede.*],
)

=== Problemas típicos de la sincronización

==== Priority inversion (inversión de prioridades)

Las tareas de baja y media prioridad pueden llegar a ejecutarse *antes* que la de alta (y eso *no está bueno*). Un escenario típico:

//#imagen([Priority inversion: el thread de baja prioridad toma el mutex, el de alta se bloquea y el de media prioridad se ejecuta primero; diapositiva 38])

#figure(
  align(image("/images/2P/priorInv.png", width: 60%)),
  caption: [Priority inversion: el thread de baja prioridad toma el mutex, el de alta se bloquea y el de media prioridad se ejecuta primero]
)

+ El thread de *baja* prioridad hace `lock()` del mutex y empieza a usar el recurso.
+ Aparece el thread de *alta* prioridad, desplaza al de baja y hace `lock()`: el mutex está ocupado, así que *se suspende* esperando.
+ Entra en escena un thread de *media* prioridad: como es *más prioritario que el de baja*, se ejecuta y *deja sin CPU al de baja*.
+ El de baja *no puede terminar ni hacer `unlock()`*, entonces *el de alta sigue esperando*... en la práctica, *indirectamente por el de media*, que tiene menos prioridad que él.

*Mitigación: Priority Inheritance (herencia de prioridad).* Mientras el thread de baja prioridad tiene tomado el mutex que necesita uno de alta, *hereda temporalmente la prioridad alta*. Así el de media no lo puede desplazar, el de baja termina rápido, hace `unlock()` y recupera su prioridad original.

//#imagen([Priority inheritance: el thread de baja prioridad corre temporalmente con prioridad alta hasta soltar el mutex; diapositiva 39])

#figure(
  align(image("/images/2P/prioInv2.png", width: 60%)),
  caption: [Priority inheritance: el thread de baja prioridad corre temporalmente con prioridad alta hasta soltar el mutex]
)


#cuadro-atencion(titulo: [No se soluciona del todo])[
Priority inheritance *mitiga* el problema, pero *no lo elimina por completo*: el thread de alta igual espera a que el de baja termine su sección crítica.
]

==== Deadlock

Un *deadlock* (o "*deadly embrace*") es una situación en la cual *dos tareas están ambas esperando a que la otra libere un recurso que necesita*. Ninguna puede avanzar.

#cuadro-ejemplo(titulo: [Ejemplo clásico])[
La tarea *A* tiene tomado el recurso `R1` y ahora pide `R2`. La tarea *B* tiene tomado `R2` y ahora pide `R1`. Cada una espera a la otra *para siempre*.

```c
void TareaA(void) {
    OSMutexPend(&R1);   // A toma R1
    OSMutexPend(&R2);   // A espera R2 (lo tiene B)...
    ...
}
void TareaB(void) {
    OSMutexPend(&R2);   // B toma R2
    OSMutexPend(&R1);   // B espera R1 (lo tiene A)...
    ...
}
```
]

*Recomendaciones para evitar deadlocks:*

- *No reservar más de un recurso a la vez.*
- *No reservar un mutex de forma directa*: abstraerlo mediante *drivers*.
- *Reservar todos los recursos juntos* antes de comenzar a usarlos.
- *Reservar los recursos en el mismo orden consistente* (en el ejemplo, que tanto A como B pidan siempre primero `R1` y luego `R2`).

==== Starvation

El *resource starvation* ocurre cuando *se le deniega a una tarea el acceso a un recurso de forma permanente*. Puede ocurrir:

- Por un *deadlock*, o
- Porque una tarea de *baja prioridad nunca se ejecuta*, ya que *siempre hay tareas de mayor prioridad en estado `ready`*.

*Posible solución: "aging"*: incrementar gradualmente la prioridad de las tareas en función del tiempo transcurrido desde que se ejecutaron por última vez.

=== Comunicación entre tareas

*¿Cómo transmitimos información entre distintas tareas o interrupciones?*

*Opción más simple: variables globales.* Por ejemplo, un flag que indica que se pulsó un botón. Pero:

- La tarea tiene que hacer *polling* para preguntar el estado, *desperdiciando tiempo de procesamiento*.
- El *tiempo de reacción* al evento depende de la *frecuencia del polling*.

*Mejor opción: pedir ayuda al RTOS.* La tarea se *suspende* y el driver del botón le avisa al RTOS que fue pulsado para que vuelva a poner la tarea en `ready`. Como el RTOS conoce todas las prioridades, puede *resumir la tarea inmediatamente* (en el caso preemptivo).

==== Semáforos binarios

Sirven para *sincronizar una ISR con una tarea*: la tarea espera (`Pend`) y la ISR avisa (`Post`).

```c
static OS_SEM buttonSem;
static OS_TCB ledTaskTCB;
static CPU_STK ledTaskStack[128];

static void myTask(void *arg) {
    OS_ERR err;
    while (true) {
        OSSemPend(&buttonSem, 0, OS_OPT_PEND_BLOCKING, NULL, &err);  // se suspende hasta que haya Post
        LED_TOGGLE();
    }
}

void PORTA_IRQHandler(void) {
    OS_ERR err;
    BUTTON_CLEAR_INTERRUPT_FLAG();
    OSSemPost(&buttonSem, OS_OPT_POST_1, &err);                      // avisa a la tarea que se pulsó el botón
}
```

#cuadro-concepto(titulo: [Cómo funciona])[
La tarea queda en `Pending` sin gastar CPU. Cuando se pulsa el botón, la ISR hace `OSSemPost`, la tarea pasa a `Ready` y, si tiene la prioridad más alta, *corre apenas termina la ISR*. Cero polling.
]

==== Semáforo contador

El caso anterior era sincronización *ISR → Task*, donde el semáforo binario es especialmente útil. Hay otro escenario donde un semáforo viene muy bien: *cantidad finita de recursos*.

#cuadro-ejemplo(titulo: [Ejemplo: canales de DMA])[
Hay, por ejemplo, 16 canales de DMA y *más drivers que canales*. Queremos un "allocator" para que cada driver haga:

`dmaAllocChannel();` → *operación del driver* → `dmaReleaseChannel();`

Si todos los canales están ocupados, el driver se debe *encolar* y esperar a que haya uno libre. Para eso sirve un *semáforo contador*, que *cuenta la disponibilidad de recursos*.
]

```c
#define DMA_NUM_CHANNELS 16
static OS_SEM semDMA;

OSSemCreate(&semDMA, DMA_NUM_CHANNELS);       // el contador arranca en N (todos libres)

channel_t dmaAllocateChannel(void) {
    OSSemPend(&semDMA);                       // espera a que haya un canal libre
    return find_free_and_reserve();
}

void dmaReleaseChannel(channel_t channel) {
    mark_as_free(channel);
    OSSemPost(&semDMA);                       // avisa que se liberó un canal
}
```

_(Los parámetros extra de `OSSemPend`/`OSSemPost` están omitidos para simplificar.)_

*Funcionamiento del contador:*

- `OSSemCreate(N)` inicia el contador en *N* (todos los recursos libres).
- `OSSemPend` (pedir un recurso): *si hay disponibles, decrementa el contador y sigue*; si no hay ninguno, *la tarea se encola y se suspende*.
- `OSSemPost` (liberar un recurso): *incrementa el contador*; si había tareas esperando, *se despierta a la siguiente de la cola*.
- Conceptualmente, un contador *negativo* indica *cuántas tareas están esperando*.

//#imagen([Máquina de estados del semáforo contador: cnt = N hasta cnt = -N con OSSemPend / OSSemPost; diapositiva 45])

#figure(
  align(image("/images/2P/sem.png", width: 100%)),
  caption: [Máquina de estados del semáforo contador: cnt = N hasta cnt = -N con OSSemPend / OSSemPost]
)

==== Colas de mensajes

Los RTOS proveen *colas FIFO* para *compartir mensajes entre tareas*. Una ISR o una tarea *publica* mensajes en la cola (`OSQPost()`) y otra tarea *los espera* (`OSQPend()`), con la posibilidad de definir un *timeout*.

//#imagen([Message Queue: Task e ISR hacen OSQPost(), la tarea receptora hace OSQPend() con timeout; diapositiva 46])

#figure(
  align(image("/images/2P/fifo.png", width: 60%)),
  caption: [Message Queue: Task e ISR hacen OSQPost(), la tarea receptora hace OSQPend() con timeout]
)

Otras funciones de la cola: `OSQCreate()`, `OSQDel()`, `OSQFlush()` y `OSQPendAbort()`.

#table(
  columns: (1fr, 2fr, 2fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Herramienta*], [*Para qué sirve*], [*Ejemplo*]),
  [*Mutex*], [*Exclusión mutua*: un solo thread usa el recurso a la vez.], [Proteger `current_position` o el bus SPI.],
  [*Semáforo binario*], [*Avisar un evento* (típicamente ISR → Task).], [Botón pulsado, fin de transferencia DMA.],
  [*Semáforo contador*], [*Contar recursos* finitos disponibles.], [Canales de DMA.],
  [*Cola de mensajes*], [*Transferir datos* (no solo avisos) entre tareas o desde una ISR.], [Caracteres recibidos por la UART.],
)

=== Usando el RTOS

==== Arquitectura de µC/OS-III

//#imagen([Arquitectura de µC/OS-III: aplicación, configuración, módulos independientes y dependientes de la CPU, BSP y librerías; diapositiva 47])

#figure(
  align(image("/images/2P/rtos.png", width: 40%)),
  caption: [Arquitectura de µC/OS-III: aplicación, configuración, módulos independientes y dependientes de la CPU, BSP y librerías]
)

#table(
  columns: (0.5fr, 2fr, 3fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*\#*], [*Módulo*], [*Contenido*]),
  [1], [*Application Code*], [El código de la aplicación (`APP.C`, `APP.H`).],
  [2], [*CPU*], [Archivos del fabricante del micro.],
  [3], [*BSP* (Board Support Package)], [Código propio de la placa (`BSP.C`, `BSP.H`).],
  [4], [*µC/OS-III* (independiente de la CPU)], [El núcleo del RTOS: tareas, scheduler, semáforos, mutex, colas, timers, etc.],
  [5], [*µC/OS-III* (específico de la CPU)], [Port a la CPU: context switch y manejo de interrupciones.],
  [6], [*µC/CPU* (específico de la CPU)], [Funciones auxiliares para la CPU.],
  [7], [*µC/LIB*], [Librerías: manejo de strings, memoria, matemática, etc.],
  [8], [*µC/OS-III Configuration*], [Archivos de configuración (`OS_CFG.H`, `OS_CFG_APP.H`).],
)

La arquitectura se divide en capas: *código de aplicación* arriba, el *RTOS* (parte independiente y parte dependiente de la CPU) en el medio, y el *hardware* abajo (CPU, timer y controlador de interrupciones).

==== Cómo dividir una aplicación en tasks

- Identificar actividades que se realizan *en simultáneo*.
- Identificar actividades de *bajo "acoplamiento"* (que dependan poco entre sí).
- *Separar el programa por funcionalidad.* Ejemplo:
  - Update del display.
  - Sincronización de hora (NTP).
  - Medición y filtrado de variables.
  - Comunicaciones con un servidor.
- Hay *drivers complejos* que van a requerir un task propio.

#cuadro-atencion(titulo: [Cuidado con el exceso (y con el defecto)])[
- Un programa con *mucha comunicación inter-task* es un *síntoma de mal diseño*. Por ejemplo, una cadena `ISR → cola → Task A → cola → Task B → cola → Task C` casi siempre se puede reemplazar por una sola `Task ABC`.
- *No crear un thread para cualquier cosa* (cada uno consume más RAM: su stack y su TCB).
- *No usar un solo thread*: para eso, ¡usar un *superloop* tradicional!
]

==== Cómo escribir un driver

La idea es que el driver *esconda* la sincronización con el RTOS, para que la aplicación lo use cómodamente. Ejemplo con un driver de SPI:

```c
void spiStart(SPIDriver *spip, const SPIConfig *config) {
    // encender clock, configurar frecuencia SCK, CPHA, CPOL, etc.
}
void spiStartExchange(SPIDriver *spip, size_t n, const void *txbuf, void *rxbuf) {
    // disparar transferencia con DMA
}
void spiExchange(SPIDriver *spip, size_t n, const void *txbuf, void *rxbuf) {
    spiStartExchange(...);
    OSSemPend(&spip->sem);        // la tarea se suspende hasta que termine el DMA
}
void SPI_DMA_Ready_ISR(void) {
    OSSemPost(&spip->sem);        // la ISR avisa que terminó la transferencia
}
void spiAcquireBus(SPIDriver *spip) {
    OSMutexPend(&spip->mtx);      // toma el bus (exclusión mutua)
}
void spiReleaseBus(SPIDriver *spip) {
    OSMutexPost(&spip->mtx);      // libera el bus
}
```

Cada herramienta cumple un rol distinto:

- El *semáforo* (`sem`) sincroniza *ISR → tarea*: `spiExchange` espera a que el DMA termine y la ISR del DMA la despierta.
- El *mutex* (`mtx`) da *exclusión mutua* sobre el bus: si dos tareas quieren usar el SPI, una espera a que la otra lo libere.

Así, la aplicación puede usar el driver sin preocuparse por la sincronización:

```c
void ThreadAccelerometerComm(void) {
    uint8_t buff[20];
    while (true) {
        _build_command(buff);
        spiAcquireBus(&SPID1);                       // reservar el bus
        spiStart(&SPID1, &config);
        spiExchange(&SPID1, sizeof(buff), buff, buff);
        spiStop(&SPID1);
        spiReleaseBus(&SPID1);                       // liberar el bus
        _interpret_accel_reading(buff);
    }
}
```

#cuadro-ejemplo(titulo: [Qué pasa mientras tanto])[
Durante `spiExchange`, la tarea está en `Pending`: *la CPU queda libre para otras tareas* mientras el DMA mueve los datos. Cuando el DMA termina, su ISR hace `OSSemPost` y la tarea vuelve a `Ready`.
]

=== Resumen final

#cuadro-concepto(titulo: [Ideas clave])[
+ Un sistema es *tiempo real* si entrega el resultado correcto *dentro del deadline*. *Hard RT*: perder deadlines es catastrófico; *soft RT*: solo degrada el rendimiento.
+ El *superloop* es simple, pero el tiempo de reacción de cada tarea puede ser tan grande como la *suma de todas las demás*, y cada cambio obliga a revalidar los deadlines.
+ Un *RTOS* ofrece *multi-tasking*: un *scheduler* que garantiza que siempre corra la tarea `ready` de *mayor prioridad* (con *IDLE* como tarea por defecto).
+ El *context switch* guarda y restaura *registros, `SP` y `PC`*; por eso cada tarea necesita su *propio stack* y su *TCB*.
+ *Preemptivo*: mejor respuesta. *Cooperativo*: más simple de sincronizar, pero peor respuesta.
+ Los *recursos compartidos* generan *condiciones de carrera*. Se protegen con *zonas críticas* (solo si son cortísimas) o con *mutex* (no desde ISR). Es responsabilidad del programador.
+ Problemas típicos: *priority inversion* (se mitiga con priority inheritance), *deadlock* (reservar en orden consistente) y *starvation* (aging).
+ Para comunicar tareas: *semáforos binarios* (ISR → Task), *semáforos contadores* (recursos finitos) y *colas de mensajes* (datos).
+ Buen diseño: dividir por funcionalidad, *poca comunicación inter-task*, y *drivers* que encapsulan mutex y semáforos.
]

#cuadro-ejemplo(titulo: [Flujo típico de una tarea con un RTOS])[
*crear tarea (`Dormant` → `Ready`) → scheduler la pone en `Running` → se suspende esperando un evento (`Pending`) → la ISR o un timeout la dejan en `Ready` → vuelve a `Running`*
]

/*
==== Referencias

- µC/OS-III Users Manual.
- µOS++ Basic concepts.
*/
