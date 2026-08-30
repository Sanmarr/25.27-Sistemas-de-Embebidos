= Clase 4 

== Arquitectura de Firmware

Al desarrollar sistemas embebidos complejos, se manejan múltiples periféricos y tareas concurrentes. Para evitar que el firmware se vuelva inmanejable y difícil de depurar, se emplea un #text(fill: red,weight: "bold")[diseño modular estructurado en capas de abstracción bien definidas].

#figure(
  image("/images/arqui.png", width: 80%),
  caption: "Ejemplo de Arquitectura de Firmware: Controlador de temperatura"
)

=== Capas e Interfaces
La arquitectura organiza los distintos módulos en una jerarquía clara:
- *Capa de Aplicación (APP)*: Es la capa de mayor jerarquía. Contiene la lógica del negocio o del funcionamiento del equipo. Sigue las reglas de la programación tradicional y es independiente del tiempo real. Nunca debe interactuar con los periféricos ni leer o escribir sus registros de forma directa; se comunica únicamente a través de los servicios de los drivers.

- *Capa de Drivers (DRV)*: Son las librerías de hardware encargadas de configurar y controlar los periféricos físicos. Resuelven las restricciones temporales del sistema y agregan versatilidad. Se subdividen en:
  
  - *Peripheral Drivers (MCAL)*: Capa de Abstracción del Microcontrolador. Configura directamente los registros de los periféricos internos del chip (como PORT, ADC, PIT o FTM). Al migrar de microcontrolador, solo esta capa debe modificarse. #text(fill: red,weight: "bold")[Capa mas baja de escritura, si cambio el procesador, solo tengo que modificar esta capa].
  
  - *Hardware Drivers (HAL)*: Capa de Abstracción de Hardware. Se encarga de controlar los elementos externos que están conectados al microcontrolador (como un sensor de temperatura externo, displays o un driver de motor). Al cambiar un componente externo, solo se altera esta capa. #text(fill: red,weight: "bold")[Capa mas baja de escritura, si cambio el procesador, solo tengo que modificar esta capa].
  
  - *Complex Drivers*: Módulos integrados que unifican el control de registros y hardware externo debido a limitaciones de tiempo extremadamente críticas o simplicidad del sistema.

== Estructura de Codigo

La estructura del código de los drivers posee 4 partes:
 - Inicialización (`Init`)
 - Servicios (`Srv`)
 - Interrupción periódica (`PISR`)
 - Interrupción dedicada (`ISR`)

 === `DRV_Init()`

 - Configura inicial del periférico y variables propias.
 - Se llama una sola vez, al inicio del programa.
 - Puede no estar presente (si no es necesario por el DRV).


=== `DRV_SrvN()`

Nunca acceder de fomra directa a los registros. Siempre a traves de estos servicios.

 - Interfaz con la capa inmediata superior.
 - Permite comenzar tareas, leer eventos y estado de los  periféricos o hardware, sin acceder directamente a los  registros.
 - Pueden haber tantas funciones como servicios se desea brindar.
 - Pueden ser llamas con cualquier frecuencia y periodicidad.
 - Puede agregar (emular) funcionalidades que no tenga el periférico.

 === `DRV_PISR()`

 - Función que debe ser llamada periódicamente, a frecuencia definida por el driver.
 - Realiza las tareas periódicas el DRV.
 - Para #text(fill: red,weight: "bold")[eventos lentos] (si es posible, es preferible un hardware polling a una interrupción dedicada).
 - Puede no estar presente (si no es necesario por el DRV).


 === `DRV_ISR()`

 - Función que es llamada por el periférico al ocurrir un evento.
 - Necesario para eventos rápidos.
 - Puede no estar presente (si no es necesario por el DRV).

 == Analisis temporal

=== Codigo Bloqueante

#figure(
  image("/images/bloq.png", width: 70%)
)

El DRV bloquea el uso de la CPU hasta que la tarea finalice / evento ocurra, y le devuelve a la APP el resultado. 

=== Polling

#figure(
  image("/images/polling.png", width: 70%)
)

-  Secuencia de 3 servicios del DRV: comenzar, consultar estado, leer resultado.
-  El DRV funciona "de pasamanos", solo enmascara los registros del HW

=== PISR

Interrupcion de timer periodica (rayado amarillo y negro). La app queda suspendida por un tiempo muy infimo en comparacion al polling al ser la interrupcion la que interroga al hardware.

#figure(
  image("/images/pisr.png", width: 70%)
)

 - Secuencia de 3 servicios del DRV: comenzar, consultar estado, leer resultado.
 - No hay conflicto si solo ocurre 1 evento entre un período del PISR.
 - El evento es capturado por el DRV y almacenado hasta que la APP lo solicite.


 === ISR (Interrupcion dedicada)

App llama al driver para que empiece la interrupcion. La app llama al driver para ver si esta listo o no (a traves de un `getStatus()` por ejemplo). El hardware genera una interrupcion que eleva la señal al driver para levantar un `flag` para que la app lo lea con un `getStatus()` y devuelva resultado con un `getResult()`.

 #figure(
  image("/images/isr.png", width: 70%)
)

 - El HW notifica al DRV mediante interrupción propia del evento.
 - No hay conflicto si solo ocurre 1 evento en el tiempo de ejecución de la ISR.

  === ISR + callback

Cada vez que quiera llamar un callback,  `DRV_ISR()` debe llamar a `DRV_SrvN()` y no directamente  al callback. #text(fill: red,weight: "bold")[Never ever launch a callback from inside a ISR or PISR] .

 #figure(
  image("/images/isrCal.png", width: 70%)
)
