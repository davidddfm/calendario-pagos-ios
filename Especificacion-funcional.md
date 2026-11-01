# Calendario de Pagos (iOS) — Especificación funcional

## Propósito y alcance

Calendario de Pagos ayuda a una persona a no olvidar sus pagos mensuales y a saber cuánto dinero le queda cada mes y cada quincena. Este documento define qué hace la app para iPhone desde el punto de vista del usuario (no habrá versión para iPad ni Apple Watch); el detalle técnico se trabajará en una etapa posterior.

Principios que guían todas las funcionalidades:

- **Mes a mes:** los pagos son compromisos que se repiten cada mes en el mismo día. Cada mes empieza con todos los pagos pendientes.
- **Quincenas:** el dinero se analiza por mes y por quincena, porque muchos usuarios cobran dos veces al mes.
- **Privacidad primero:** los datos financieros son personales. Todo lo que se vea sin desbloquear el teléfono (notificaciones, widget) evita mostrar montos.
- **100% local:** el usuario puede usar la app sin registrarse. Pagos, salario, moneda e historial se guardan solo en el iPhone; no hay servidor propio ni sincronización. La app funciona por completo sin conexión a internet.
- **Una sola moneda:** la app trabaja en dólares o en euros, nunca en ambos. El usuario la elige al empezar.

Cada funcionalidad se describe con lo que el usuario puede hacer y las reglas que la app debe cumplir. Las reglas llevan un código (por ejemplo, **PAG-03**) para poder referirse a ellas en la etapa técnica y en las pruebas.

## 1. Navegación y estructura

La app tiene tres pestañas fijas en la parte inferior y un menú secundario para las opciones menos frecuentes.

| Pestaña | Qué encuentra el usuario |
| --- | --- |
| Inicio | Pagos de hoy, análisis quincenal, lista completa de pagos y buscador |
| Calendario | Vista mensual con los días que tienen pagos y acceso a las herramientas financieras |
| Perfil | Dashboard financiero: disponible del mes, gastos por categoría, fondo de emergencia |

**Menú secundario** (accesible desde Inicio): Acerca de, Historial de pagos y Configuración. En iOS no se usa el menú lateral típico de Android; la forma de presentarlo (botón en la barra superior, hoja inferior, etc.) se decide en diseño.2222222

- **NAV-01:** Desde cualquier pestaña, el usuario llega a crear un pago en un máximo de dos toques.
- **NAV-02:** La pestaña seleccionada y la posición se conservan al cambiar entre pestañas.

## 2. Gestión de pagos

El usuario registra sus compromisos mensuales una sola vez y la app los repite cada mes en el mismo día.

**Lo que el usuario puede hacer**

- Crear un pago con nombre, monto, día del mes y categoría.
- Editar cualquier dato de un pago existente.
- Eliminar un pago.
- Buscar pagos por nombre desde Inicio.
- Ver en Inicio los pagos de hoy y el total de cada quincena.

**Reglas**

- **PAG-01:** Nombre, monto y día son obligatorios. El día va del 1 al 31.
- **PAG-02:** La categoría es opcional y se elige de la lista fija de la sección 9. Si no se elige, el pago queda en “Gastos”.
- **PAG-03:** Cada pago pertenece automáticamente a una quincena: la Primera (días 1 al 15) o la Segunda (días 16 al 31). El usuario no la elige.
- **PAG-04:** Eliminar un pago pide confirmación antes de borrarlo.
- **PAG-05:** La búsqueda filtra mientras el usuario escribe, sin necesidad de pulsar un botón, e ignora mayúsculas y acentos.
- **PAG-06:** Inicio muestra dos secciones fijas: “Para hoy” (pagos con el día actual) y “Análisis quincenal” (total de cada quincena). Tocar una quincena abre su detalle (sección 6).
- **PAG-07:** Si un pago está en un día que el mes no tiene (por ejemplo, el 31 en febrero), se muestra el último día de ese mes.
- **PAG-08:** Cuando no hay ningún pago registrado, Inicio muestra una guía breve de bienvenida con un botón para crear el primer pago.

## 3. Marcar pagos como pagados e historial

El usuario marca cada pago como pagado dentro del mes en curso, y la app guarda un registro de cada mes para consultarlo y corregirlo después.

**Marcar como pagado**

- **MAR-01:** Cada pago tiene una casilla para marcarlo o desmarcarlo como pagado en cuatro lugares: Inicio, el detalle de quincena, el detalle de un día en el Calendario y el widget.
- **MAR-02:** Las casillas solo se muestran para el mes actual. Los meses anteriores se corrigen desde el Historial.
- **MAR-03:** Al empezar un mes nuevo, todos los pagos aparecen de nuevo como pendientes. Lo marcado en el mes anterior queda en el Historial.
- **MAR-04:** Al marcar un pago, la app guarda una foto de cómo era en ese momento: nombre, monto y categoría. Si después se edita el pago, el registro del mes no cambia.
- **MAR-05:** Si el monto de un pago cambió después de marcarlo, el pago muestra “pagado por $X” con el monto que se registró al pagarlo.

**Historial mensual**

Se abre desde “Historial de pagos” en el menú secundario o desde un botón en el Dashboard.

- **HIS-01:** Muestra una lista de meses. Cada mes indica el total pagado, cuántos pagos se cumplieron y el porcentaje de cumplimiento.
- **HIS-02:** Incluye una gráfica de barras con el total pagado de los últimos 6 meses.
- **HIS-03:** Al tocar un mes se ven sus pagos separados en pagados y pendientes.
- **HIS-04:** Dentro de un mes pasado, el usuario puede marcar o desmarcar pagos para corregir el registro.

## 4. Dashboard financiero (pestaña Perfil)

El Dashboard le dice al usuario, de un vistazo, cuánto le queda del salario, en qué se le va el dinero y cuánto debería tener ahorrado para emergencias. Todo se calcula a partir del salario neto mensual configurado y de los pagos registrados.

| Tarjeta | Qué muestra | Cálculo |
| --- | --- | --- |
| Disponible este mes | Dinero que queda y barra de progreso del gasto | Salario mensual − total de pagos registrados |
| Gastos por categoría | Gráfico circular con el porcentaje de cada categoría | Suma de pagos por categoría ÷ total de pagos |
| Tu fondo de emergencia | Monto necesario para 3, 6 y 12 meses | Total mensual de pagos × 3, × 6 y × 12 |

**Reglas**

- **DAS-01:** La barra de “Disponible este mes” es verde mientras el gasto sea 50% del salario o menos, y naranja cuando lo supera.
- **DAS-02:** Si los pagos superan el salario, el disponible se muestra en negativo y de forma destacada.
- **DAS-03:** El gráfico usa las categorías fijas de la app y muestra solo las que tienen pagos.
- **DAS-04:** Si no hay salario configurado, en lugar de las tarjetas de salario se muestra una invitación a configurarlo, con acceso directo a Ajustes.
- **DAS-05:** El salario neto mensual admite hasta 9,999,999.
- **DAS-06:** El Dashboard tiene un acceso directo al Historial mensual (sección 3).

## 5. Calendario

El Calendario muestra el mes completo con los días que tienen pagos marcados, para que el usuario vea cómo se reparten sus compromisos.

- **CAL-01:** Vista mensual que destaca los días con pagos programados.
- **CAL-02:** Botones para ir al mes anterior y al siguiente, sin límite.
- **CAL-03:** Al tocar un día se abre su detalle: fecha completa, total del día y lista de pagos con su categoría y monto.
- **CAL-04:** En el mes actual, el detalle del día muestra cuántos pagos van pagados, con una barra de progreso, y una casilla en cada pago para marcarlo.
- **CAL-05:** En otros meses, el detalle muestra los pagos sin casillas. Las correcciones se hacen desde el Historial.
- **CAL-06:** Tocar un pago en el detalle abre su edición.
- **CAL-07:** La barra superior del Calendario da acceso a las herramientas: Exportar, ¿Puedo costearlo?, Detector de fugas y Plan 50/30/20 (sección 7).

## 6. Análisis quincenal

Cada quincena tiene su propia pantalla para que el usuario sepa cuánto le queda de lo que cobra en ella.

- **QUI-01:** Hay una pantalla para la Primera quincena (días 1 al 15) y otra para la Segunda (días 16 al 31), con la lista de sus pagos.
- **QUI-02:** Cada pantalla muestra el “Saldo restante (aproximado)”: salario mensual ÷ 2 menos el total de pagos de esa quincena.
- **QUI-03:** Cada pago tiene su casilla de pagado (solo mes actual, regla MAR-02).
- **QUI-04:** Si no hay salario configurado, la pantalla muestra la lista de pagos y una invitación a configurar el salario en lugar del saldo.

## 7. Herramientas financieras

Estas herramientas complementan el seguimiento de pagos. Todas usan el salario configurado y los pagos registrados. Ninguna modifica los datos del usuario.

**¿Puedo costearlo?**

Responde si el usuario puede asumir un nuevo gasto mensual sin descuidar su ahorro.

- **HER-01:** El usuario ingresa el monto del nuevo gasto y elige si es Necesidad o Deseo.
- **HER-02:** La app recalcula la distribución 50/30/20 incluyendo ese gasto y muestra cuánto quedaría para ahorro.
- **HER-03:** Un semáforo resume el resultado según el ahorro que queda, como porcentaje del salario:

| Color | Ahorro restante |
| --- | --- |
| Verde | 15% del salario o más |
| Amarillo | Entre 10% y menos de 15% |
| Rojo | Menos de 10%, o el gasto supera el ingreso |

**Detector de fugas**

Muestra cuánto cuesta cada pago al año, para que el usuario detecte suscripciones o gastos que conviene recortar.

- **HER-04:** Lista todos los pagos ordenados de mayor a menor monto, con su costo anual (monto × 12).
- **HER-05:** Muestra el total anual de todos los pagos.
- **HER-06:** Trata cada pago como un gasto mensual recurrente.

**Plan 50/30/20**

- **HER-07:** Muestra cómo debería repartirse el salario mensual: 50% necesidades, 30% deseos y 20% ahorro, con los montos calculados a partir del salario configurado. Es solo informativo.

**Exportar datos**

- **HER-08:** Genera un archivo de hoja de cálculo (CSV) con todos los pagos, llamado pagos-AAAA-MM-DD.csv con la fecha del día.
- **HER-09:** En iOS, el usuario elige qué hacer con el archivo: guardarlo en Archivos, enviarlo por correo o mensaje, o abrirlo en otra app.
- **HER-10:** Se puede exportar desde el Calendario y desde Inicio.

## 8. Recordatorios y notificaciones

La app avisa una vez al día, a la hora que el usuario elija, cuando ese día tiene pagos. El objetivo es que el aviso llegue siempre, aunque el usuario no abra la app.

- **NOT-01:** Las notificaciones vienen activadas por defecto, a las 8:00.
- **NOT-02:** El usuario puede cambiar la hora en Ajustes. El cambio aplica desde el siguiente aviso, sin reiniciar la app.
- **NOT-03:** Solo se envía aviso si ese día hay pagos. Se envía como máximo uno por día.
- **NOT-04:** El aviso debe seguir llegando tras reiniciar el teléfono o actualizar la app.
- **NOT-05:** El usuario puede desactivar las notificaciones con un interruptor en Ajustes. Al hacerlo, no recibe ningún aviso más hasta reactivarlas.
- **NOT-06:** La primera vez, la app pide permiso para enviar notificaciones. Si el usuario lo niega, Ajustes indica que están bloqueadas y ofrece ir a los ajustes del iPhone para activarlas.
- **NOT-07:** El aviso muestra cuántos pagos hay hoy y sus nombres, nunca montos, porque se ve con el teléfono bloqueado.
- **NOT-08:** Si el usuario ya marcó como pagados todos los pagos del día antes de la hora del aviso, no se envía.
- **NOT-09:** Los avisos son solo informativos: no tienen acciones como "Marcar como pagado". Tocar el aviso abre la app en Inicio, con la sección “Para hoy” a la vista.

## 9. Configuración, moneda, categorías, seguridad y apariencia

Ajustes reúne el salario, la moneda, los recordatorios y la protección de la app. Las categorías son fijas y no se configuran.

**Salario**

- **CFG-01:** El usuario ingresa su salario neto mensual (hasta 9,999,999). Es la base de todos los cálculos del Dashboard, las quincenas y las herramientas.

**Moneda**

La app trabaja con una sola moneda a la vez: dólares estadounidenses (USD, $) o euros (EUR, €). Nunca se usan ambas al mismo tiempo ni se convierten, porque la app es 100% local y no tiene tipos de cambio.

- **MND-01:** La primera vez que se abre la app, antes de registrar nada, el usuario elige la moneda: dólares o euros.
- **MND-02:** Todos los montos de la app (pagos, salario, totales, saldos, herramientas e Historial) se muestran en esa moneda y con su símbolo.
- **MND-03:** El usuario puede cambiar la moneda en Ajustes. Los montos no se convierten: solo cambia el símbolo, y la app lo advierte antes de confirmar.
- **MND-04:** El CSV exportado indica la moneda de la app.

**Categorías**

Estas son las categorías de la app, iguales para todos los usuarios:

| Categoría | Ejemplos |
| --- | --- |
| Gastos | Compras del día a día que no encajan en otra categoría: supermercado, comidas, ropa, compras diversas |
| Ahorros | Aportes a cuentas o fondos de ahorro |
| Inversiones | Aportes a fondos, acciones, planes de pensión |
| Bienestar | Salud, medicinas, consultas, gimnasio, terapias, suscripciones de entretenimiento |
| Préstamos | Cuotas de préstamos, pagos de tarjetas de crédito |
| Transportes | Combustible, transporte público, cuota y seguro del vehículo |
| Servicios | Alquiler, hipoteca, luz, agua, gas, internet, teléfono |

- **CAT-01:** La lista es fija: el usuario no puede crear, editar, eliminar ni reordenar categorías, y Ajustes no tiene gestión de categorías.
- **CAT-02:** Al crear o editar un pago, el usuario elige una categoría de la lista. Si no elige, el pago queda en “Gastos”.
- **CAT-03:** Cada categoría se llama igual en todas las pantallas: el pago, el detalle del día, el Dashboard, el Historial y el CSV.

**Bloqueo de la app**

- **SEG-01:** Opción en Ajustes > Seguridad, apagada por defecto, que pide Face ID, Touch ID o el código del iPhone para abrir la app.
- **SEG-02:** El usuario elige cuánto tiempo en segundo plano debe pasar antes de volver a pedirlo: inmediatamente, 1, 5 o 15 minutos. Por defecto, 1 minuto.
- **SEG-03:** Mientras la app está bloqueada no se ve ningún dato.
- **SEG-04:** Si el iPhone deja de tener código de desbloqueo, el bloqueo de la app se desactiva solo y se avisa al usuario.

**Apariencia**

- **APA-01:** La app sigue el modo claro u oscuro del iPhone.

## 10. Widget “Pagos de hoy”

El widget muestra los pagos de hoy y si ya se pagaron, sin abrir la app y sin revelar dinero. iOS no permite redimensionar libremente como Android, así que los cuatro diseños originales se adaptan a los tamaños fijos de iOS.

| Diseño original (Android) | Tamaño en iOS | Qué muestra |
| --- | --- | --- |
| Franja (2×1, 4×1) | Pantalla bloqueada: línea y rectángulo | Número de pagos pendientes hoy, o “Todo al día” |
| Tarjeta (2×2) | Pequeño | Número grande de pendientes y “1 de 3 pagados”; “¡Todo al día!” con palomita si no queda nada |
| Lista (4×2) | Mediano | Fecha y pagos de hoy, cada uno con su estado: círculo “Pendiente” o palomita y tachado “Pagado” |
| Lista alta (4×3 o más) | Grande | Lo mismo que Mediano, más barra de progreso (“2 de 3 pagados”) y más filas |

**Reglas**

- **WID-01:** El widget nunca muestra montos, totales ni el salario. Solo nombres de pagos y su estado. No hay ajuste para cambiarlo.
- **WID-02:** Usa una paleta neutra fija (grises fríos y verde para “pagado”), con versión clara y oscura, legible sobre cualquier fondo de pantalla.
- **WID-03:** Se actualiza al marcar o desmarcar pagos, al crear, editar o eliminar pagos y al cambiar el salario.
- **WID-04:** Poco después de medianoche cambia a los pagos del nuevo día.
- **WID-05:** Tocar cualquier parte del widget fuera de una casilla abre la app.
- **WID-06:** Si el bloqueo de la app está activo, el widget sigue mostrando nombres y estados (no son datos de dinero).
- **WID-07:** En los tamaños Mediano y Grande, cada pago tiene una casilla para marcarlo o desmarcarlo como pagado sin abrir la app. El cambio se refleja de inmediato en la app y en el Historial.

## 11. Modelo de negocio y privacidad

La app es de pago: el usuario la compra una sola vez en el App Store y tiene todas las funcionalidades, sin anuncios ni compras adicionales.

- **NEG-01:** No hay versión gratuita con anuncios ni publicidad de ningún tipo.
- **NEG-02:** No hay compras dentro de la app ni funciones bloqueadas: todo lo descrito en este documento está incluido en el precio.
- **NEG-03:** La app no rastrea al usuario ni comparte datos con terceros, por lo que no muestra formularios de consentimiento ni pide permiso de rastreo.
- **NEG-04:** Pago único en el App Store, sin suscripción. Las futuras actualizaciones quedan incluidas. No hay periodo de prueba, porque el App Store no lo ofrece para apps de pago único.

## 12. Decisiones para iOS

Estas decisiones ya están tomadas y aplicadas en las secciones correspondientes. Al final, no quedan preguntas abiertas.

| Tema | Decisión | Dónde aplica |
| --- | --- | --- |
| Capturas y selector de apps | No se bloquean capturas ni se oculta el contenido en el selector de apps | Sección 9 (se quitó) |
| Datos y respaldo | 100% local, sin respaldo, sin sincronización y sin importación | Propósito y alcance |
| Widget interactivo | Sí: se puede marcar un pago como pagado desde el widget | WID-07, MAR-01 |
| Notificaciones | Solo informativas, sin acciones | NOT-09 |
| Dispositivos | Solo iPhone | Propósito y alcance |
| Moneda | Una sola moneda en toda la app, USD o EUR, elegida al empezar; nunca se mezclan | MND-01 a MND-04 |
| Categorías | Lista fija de 7; el usuario no puede crear ni modificar categorías | CAT-01 a CAT-03 |
| Siri y Atajos | Sin integración por ahora | — |
| Modelo de negocio | Pago único en el App Store, sin anuncios ni compras dentro de la app | NEG-01 a NEG-04 |

**Estado**

Ninguna pregunta abierta. Todas las reglas propuestas quedaron confirmadas.

