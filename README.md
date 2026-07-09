# 1. JUSTIFICACIÓN DE LA MODULARIZACIÓN Y GRUPOS DE SEGURIDAD (EJERCICIO 1)

El diseño de esta arquitectura en Terraform para el **Stack MEAN** se fundamenta en el principio de **Separación de Responsabilidades (Separation of Concerns)** y en las mejores prácticas de la industria de Ingeniería DevOps. A continuación, se justifica técnicamente la estructura modular adoptada, los componentes de red y la estrategia de seguridad perimetral.

---

## 1.1. Justificación del Número de Módulos (3 Módulos)

El proyecto se dividió estrictamente en **3 módulos funcionales**: `network`, `security` y `compute`.

Desarrollar este número específico de módulos se justifica porque cada uno representa una capa de infraestructura con un **ciclo de vida y un ritmo de cambio totalmente distinto** en entornos de producción:

* **La Capa de Red (`network`) casi nunca cambia:** Una vez establecida la topología de subredes, bloques CIDR y enrutadores, la infraestructura base permanece estática a lo largo de los meses o años.
* **La Capa de Seguridad (`security`) cambia por auditoría:** Las reglas de los firewalls y la apertura de puertos se modifican frecuentemente para responder a nuevas necesidades de conectividad o restricciones políticas.
* **La Capa de Cómputo (`compute`) cambia constantemente:** Las máquinas virtuales se destruyen, escalan o modifican de tamaño de forma periódica para responder a la demanda del tráfico, despliegues continuos o actualizaciones de software.

Si se concentrara toda la infraestructura en un único archivo gigante, un cambio menor en una máquina virtual podría poner en riesgo accidentalmente la configuración de toda la red de la organización.

---

## 1.2. Explicación Detallada de Cada Módulo

### A. Módulo de Red (`modules/network`)

Este módulo se encarga de construir el **aislamiento topológico** y el esqueleto de comunicaciones sobre AWS.

* **VPC (Virtual Private Cloud):** Crea un centro de datos virtual privado, lógicamente aislado de otros entornos dentro de la nube de AWS.
* **Segmentación de Subredes:** Divide la red en tres subredes estratégicas. Dos subredes públicas distribuidas en zonas de disponibilidad distintas (`us-east-1a` y `us-east-1b`) —requeridas obligatoriamente por el Balanceador de Carga para asegurar la alta disponibilidad— y una subred privada.
* **Internet Gateway (IGW):** Provee una puerta de enlace de entrada y salida web para las subredes públicas.
* **NAT Gateway (Network Address Translation):** Asociado a una IP Elástica, permite que el nodo de MongoDB (aislado en la subred privada) salga a internet de forma segura para descargar parches o dependencias de software, pero **impide por completo** que cualquier entidad externa inicie una conexión directa hacia la base de datos desde internet.

### B. Módulo de Seguridad (`modules/security`)

Este módulo actúa como la **capa de firewall perimetral e interno**, dictando las reglas de comunicación mediante Grupos de Seguridad (*Security Groups*). Implementa de forma estricta el **Principio de Menor Privilegio**.

* **`mean-alb-sg` (Firewall del Balanceador):** Es el único componente expuesto directamente al mundo exterior. Solo permite tráfico entrante en el puerto `80` (HTTP) desde cualquier dirección IP (`0.0.0.0/0`).
* **`mean-web-sg` (Firewall del Nodo Web Nginx/Node.js):** Permite tráfico en el puerto `80`, pero de forma **restringida**. No acepta peticiones de internet directamente; solo procesa paquetes cuyo origen sea estrictamente el Grupo de Seguridad del Balanceador de Carga.
* **`mean-db-sg` (Firewall de MongoDB):** Bloquea todo el acceso excepto en el puerto nativo de la base de datos (`27017`). Por motivos de seguridad corporativa, solo acepta peticiones entrantes que provengan del Grupo de Seguridad del Nodo Web, neutralizando vectores de ataque internos si otros segmentos de la red fuesen comprometidos.

### C. Módulo de Cómputo (`modules/compute`)

Este módulo se encarga de aprovisionar el **poder de procesamiento** del Stack MEAN, encapsulando y ordenando la creación de las instancias EC2.

* **Nodo Web (`mean-web-node`):** Una máquina virtual `t3.micro` alojada en la subred pública. Recibe de forma parametrizada el ID de la AMI (la cual puede ser la imagen inmutable de Node/Nginx generada en la práctica de Packer) para levantar la capa de aplicación de inmediato.
* **Nodo de Datos (`mean-mongodb-node`):** Una máquina virtual alojada deliberadamente en la subred privada. Al no asignársele una IP pública, queda completamente invisibilizada para internet, utilizando una imagen limpia de Ubuntu dedicada exclusivamente a ejecutar el motor de MongoDB.
