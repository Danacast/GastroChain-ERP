-- ============================================================
-- BASE DE DATOS: GastroChainERP
-- Modelo Relacional Transaccional + RBAC + Data Warehouse (BI)
-- ============================================================

DROP DATABASE IF EXISTS GastroChainERP;
CREATE DATABASE GastroChainERP;
USE GastroChainERP;

-- ============================================================
-- CAPA DE DATOS: TABLAS MAESTRAS (PADRE / INDEPENDIENTES)
-- ============================================================

-- 1. Sedes / Sucursales Corporativas
CREATE TABLE Sedes (
    id_sucursal INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    zona_geografica VARCHAR(50) NOT NULL,
    capacidad_maxima INT NOT NULL
);

-- 2. Categorías de Menú
CREATE TABLE Categorias (
    codcategoria INT PRIMARY KEY AUTO_INCREMENT,
    nomcategoria VARCHAR(50) NOT NULL
);

-- 3. Clientes Registrados
CREATE TABLE Clientes (
    cedcliente VARCHAR(20) PRIMARY KEY,
    nomcliente VARCHAR(100) NOT NULL,
    telefono VARCHAR(15)
);

-- 4. Directorio Oficial de Proveedores
CREATE TABLE Proveedores (
    id_proveedor INT PRIMARY KEY AUTO_INCREMENT,
    nombre_empresa VARCHAR(100) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    categoria VARCHAR(50) NOT NULL, -- Proteínas, Vegetales, Lácteos, Bebidas, Condimentos
    deuda_total DECIMAL(12,2) DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'activo'
);

-- 5. Catálogo de Platos del Menú
CREATE TABLE Platos_Menu (
    id_plato INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plato VARCHAR(80) NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL,
    clasificacion VARCHAR(30) NOT NULL, -- Entradas, Platos Principales, Bebidas, Postres
    cantidad_venta INT DEFAULT 0,
    codcategoria INT,
    FOREIGN KEY (codcategoria) REFERENCES Categorias(codcategoria)
);

-- 6. Roles del Sistema (RBAC)
CREATE TABLE Roles (
    id_rol INT PRIMARY KEY AUTO_INCREMENT,
    nombre_rol VARCHAR(30) NOT NULL UNIQUE, -- Dueno, Gerente, Mesero, Cocina, Cajero
    descripcion VARCHAR(150)
);

-- 7. Permisos / Módulos del ERP (RBAC)
CREATE TABLE Permisos (
    id_permiso INT PRIMARY KEY AUTO_INCREMENT,
    codigo_permiso VARCHAR(50) NOT NULL UNIQUE, -- ej: 'VER_BI', 'CREAR_RESERVA', 'ANULAR_FACTURA'
    modulo VARCHAR(40) NOT NULL
);

-- ============================================================
-- CAPA DE DATOS: TABLAS CON DEPENDENCIAS SIMPLES (FKD / RBAC)
-- ============================================================

-- 8. Talento Humano y Control de Acceso (RBAC)
CREATE TABLE Empleados (
    id_empleado INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salario DECIMAL(12,2) NOT NULL,
    tareas_diarias TEXT,
    estado VARCHAR(20) DEFAULT 'activo',
    id_sucursal INT NOT NULL,
    id_rol INT NOT NULL,
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal),
    FOREIGN KEY (id_rol) REFERENCES Roles(id_rol)
);

-- 9. Mesas por Sucursal
CREATE TABLE Mesas (
    id_mesa INT PRIMARY KEY AUTO_INCREMENT,
    nro_mesa VARCHAR(10) NOT NULL,
    capacidad INT NOT NULL,
    id_sucursal INT NOT NULL,
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal)
);

-- 10. Insumos e Ingredientes de Inventario
CREATE TABLE Insumos (
    id_insumo INT PRIMARY KEY AUTO_INCREMENT,
    nombre_insumo VARCHAR(80) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL, -- Gramos, Mililitros, Unidades
    precio_actual DECIMAL(10,2) NOT NULL,
    id_proveedor INT,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

-- 11. Reservas y Control de Aforo
CREATE TABLE Reservas (
    id_reserva INT PRIMARY KEY AUTO_INCREMENT,
    nombre_cli VARCHAR(100) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    cantidad INT NOT NULL,
    estado VARCHAR(30) DEFAULT 'Solicitada', -- Solicitada, Validada, Confirmada, ConfirmadaConAlerta, EnCurso, Finalizada, Cancelada, Rechazada
    id_sucursal INT NOT NULL,
    id_mesa INT,
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal),
    FOREIGN KEY (id_mesa) REFERENCES Mesas(id_mesa)
);

-- 12. Facturas de Venta Transaccionales
CREATE TABLE Facturas (
    nrofactura INT PRIMARY KEY AUTO_INCREMENT,
    fechafactura DATETIME NOT NULL,
    valortotal DECIMAL(12,2) DEFAULT 0.00,
    cedcliente VARCHAR(20),
    id_sucursal INT NOT NULL,
    FOREIGN KEY (cedcliente) REFERENCES Clientes(cedcliente),
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal)
);

-- 13. Órdenes de Compra a Proveedores
CREATE TABLE Ordenes_Compra (
    id_orden_compra INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    valor_total DECIMAL(12,2) DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'Pendiente',
    id_sucursal INT NOT NULL,
    id_proveedor INT NOT NULL,
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

-- 14. Mensajería Interna Jerárquica Cifrada
CREATE TABLE Mensajes_Chat (
    id_mensaje INT PRIMARY KEY AUTO_INCREMENT,
    id_emisor INT NOT NULL,
    id_receptor INT NOT NULL,
    contenido TEXT NOT NULL,
    fecha_hora DATETIME NOT NULL,
    cifrado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_emisor) REFERENCES Empleados(id_empleado),
    FOREIGN KEY (id_receptor) REFERENCES Empleados(id_empleado)
);

-- ============================================================
-- CAPA DE DATOS: RELACIONES COMPUESTAS (DFNE - 3FN/4FN/5FN)
-- ============================================================

-- 15. Matriz Rol - Permiso (RBAC)
CREATE TABLE Rol_Permisos (
    id_rol INT,
    id_permiso INT,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES Roles(id_rol),
    FOREIGN KEY (id_permiso) REFERENCES Permisos(id_permiso)
);

-- 16. Recetas (Composición de Insumos por Plato)
CREATE TABLE Recetas (
    id_plato INT,
    id_insumo INT,
    cantidad_requerida DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_plato, id_insumo),
    FOREIGN KEY (id_plato) REFERENCES Platos_Menu(id_plato),
    FOREIGN KEY (id_insumo) REFERENCES Insumos(id_insumo)
);

-- 17. Stock e Inventario de Insumos por Sede
CREATE TABLE Inventario_Sedes (
    id_sucursal INT,
    id_insumo INT,
    stock_actual DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_minimo DECIMAL(12,2) NOT NULL DEFAULT 10.00,
    PRIMARY KEY (id_sucursal, id_insumo),
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal),
    FOREIGN KEY (id_insumo) REFERENCES Insumos(id_insumo)
);

-- 18. Detalle de Factura (Venta de Platos)
CREATE TABLE Factura_Platos (
    nrofactura INT,
    id_plato INT,
    cantidadvendida INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (nrofactura, id_plato),
    FOREIGN KEY (nrofactura) REFERENCES Facturas(nrofactura),
    FOREIGN KEY (id_plato) REFERENCES Platos_Menu(id_plato)
);

-- 19. Detalle de Orden de Compra (Insumos Comprados)
CREATE TABLE Detalle_Orden_Compra (
    id_orden_compra INT,
    id_insumo INT,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_orden_compra, id_insumo),
    FOREIGN KEY (id_orden_compra) REFERENCES Ordenes_Compra(id_orden_compra),
    FOREIGN KEY (id_insumo) REFERENCES Insumos(id_insumo)
);

-- ============================================================
-- CAPA DE PROCESAMIENTO: TRIGGERS Y REGLAS DE NEGOCIO
-- ============================================================

-- A. Trigger de Alerta Automática de Aforo Crítico (>= 90%)
DELIMITER //
CREATE TRIGGER tr_VerificarAlertaAforo
BEFORE INSERT ON Reservas
FOR EACH ROW
BEGIN
    DECLARE v_capacidad_max INT;
    DECLARE v_comensales_actuales INT;
    DECLARE v_nuevo_total INT;
    DECLARE v_porcentaje_ocupacion DECIMAL(5,2);

    SELECT capacidad_maxima INTO v_capacidad_max 
    FROM Sedes 
    WHERE id_sucursal = NEW.id_sucursal;

    SELECT IFNULL(SUM(cantidad), 0) INTO v_comensales_actuales
    FROM Reservas
    WHERE id_sucursal = NEW.id_sucursal
      AND DATE(fecha_hora) = DATE(NEW.fecha_hora)
      AND estado IN ('Confirmada', 'ConfirmadaConAlerta', 'EnCurso');

    SET v_nuevo_total = v_comensales_actuales + NEW.cantidad;
    SET v_porcentaje_ocupacion = (v_nuevo_total / v_capacidad_max) * 100;

    IF v_porcentaje_ocupacion >= 100.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aforo completo: No hay disponibilidad en la sucursal.';
    ELSEIF v_porcentaje_ocupacion >= 90.00 THEN
        SET NEW.estado = 'ConfirmadaConAlerta';
    ELSE
        SET NEW.estado = 'Confirmada';
    END IF;
END; //
DELIMITER ;

-- B. Trigger de Descuento de Inventario Automatizado por Venta (Receta)
DELIMITER //
CREATE TRIGGER tr_DescontarInventarioVenta
AFTER INSERT ON Factura_Platos
FOR EACH ROW
BEGIN
    DECLARE v_sucursal INT;

    SELECT id_sucursal INTO v_sucursal 
    FROM Facturas 
    WHERE nrofactura = NEW.nrofactura;

    UPDATE Inventario_Sedes inv
    JOIN Recetas rec ON inv.id_insumo = rec.id_insumo
    SET inv.stock_actual = inv.stock_actual - (rec.cantidad_requerida * NEW.cantidadvendida)
    WHERE rec.id_plato = NEW.id_plato
      AND inv.id_sucursal = v_sucursal;
END; //
DELIMITER ;

-- ============================================================
-- DATOS INICIALES: SEDES, ROLES, PERMISOS, MENÚ E INVENTARIO
-- ============================================================

-- 1. Sedes
INSERT INTO Sedes (id_sucursal, nombre, direccion, zona_geografica, capacidad_maxima) VALUES
(1, 'GastroChain Chapinero', 'Calle 63 # 9-45', 'Chapinero', 80),
(2, 'GastroChain Zona Rosa', 'Carrera 13 # 82-30', 'Zona T', 100),
(3, 'GastroChain Usaquén', 'Calle 119 # 6-24', 'Usaquén', 70);

-- 2. Roles y Permisos (RBAC)
INSERT INTO Roles (id_rol, nombre_rol, descripcion) VALUES
(1, 'Dueno', 'Acceso total a finanzas, reportes BI multi-sede y configuración general'),
(2, 'Gerente', 'Gestión operativa de sucursal, alertas de aforo, compras y personal'),
(3, 'Mesero', 'Toma de pedidos, registro de reservas en salón y consulta de mesas'),
(4, 'Cocina', 'Visualización de comandas KDS, tiempos de despacho y alertas de stock'),
(5, 'Cajero', 'Liquidación de cuentas, facturación y arqueo de caja');

INSERT INTO Permisos (id_permiso, codigo_permiso, modulo) VALUES
(1, 'VER_DASHBOARD_BI', 'Analytics'),
(2, 'GESTIONAR_COMPRAS', 'Sourcing'),
(3, 'GESTIONAR_PERSONAL', 'Staff'),
(4, 'CREAR_RESERVA', 'Reservations'),
(5, 'GESTIONAR_KDS', 'Kitchen'),
(6, 'EMITIR_FACTURA', 'Billing');

INSERT INTO Rol_Permisos (id_rol, id_permiso) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), -- Dueño: todos
(2, 2), (2, 3), (2, 4), (2, 6),                 -- Gerente
(3, 4),                                         -- Mesero
(4, 5),                                         -- Cocina
(5, 6);                                         -- Cajero

-- 3. Empleados de Prueba
INSERT INTO Empleados (id_empleado, nombre, email, password_hash, salario, tareas_diarias, id_sucursal, id_rol) VALUES
(1, 'Carlos Mendoza', 'dueno@gastrochain.com', 'hash_demo_123', 12000000.00, 'Supervisión estratégica multi-sede', 1, 1),
(2, 'Laura Gómez', 'gerente.chapinero@gastrochain.com', 'hash_demo_123', 4800000.00, 'Control de aforo, inventario y cierres', 1, 2),
(3, 'Andrés Rojas', 'mesero1@gastrochain.com', 'hash_demo_123', 1800000.00, 'Atención de mesas 1 a 10 y reservas', 1, 3),
(4, 'Chef Mateo Silva', 'cocina1@gastrochain.com', 'hash_demo_123', 3500000.00, 'Despacho de comandas y control PEPS', 1, 4),
(5, 'Sofía Castro', 'caja1@gastrochain.com', 'hash_demo_123', 2100000.00, 'Facturación y arqueo de turno', 1, 5);

-- 4. Categorías y Proveedores
INSERT INTO Categorias (codcategoria, nomcategoria) VALUES
(1, 'Entradas'),
(2, 'Platos Principales'),
(3, 'Bebidas'),
(4, 'Postres');

INSERT INTO Proveedores (id_proveedor, nombre_empresa, contacto, telefono, categoria, deuda_total, estado) VALUES
(1, 'Carnes Premium S.A.', 'Roberto Salcedo', '310-482-1234', 'Proteínas', 2400000.00, 'activo'),
(2, 'Verduras Frescas Ltda.', 'Patricia Niño', '314-721-5678', 'Vegetales', 0.00, 'activo'),
(3, 'Vinos & Licores BG', 'Gabriel Botero', '321-933-9012', 'Bebidas', 5100000.00, 'activo'),
(4, 'Lácteos del Valle', 'Marcela Ríos', '315-684-3456', 'Lácteos', 800000.00, 'activo');

-- 5. Insumos
INSERT INTO Insumos (id_insumo, nombre_insumo, unidad_medida, precio_actual, id_proveedor) VALUES
(101, 'Lomo fino de res', 'Gramos', 48.00, 1),
(102, 'Camarón tigre limpio', 'Gramos', 65.00, 1),
(103, 'Arroz Arborio', 'Gramos', 14.00, 2),
(104, 'Hongos Portobello', 'Gramos', 28.00, 2),
(105, 'Vino Malbec Reserva (Botella 750ml)', 'Unidades', 68000.00, 3),
(106, 'Crema de leche entera', 'Mililitros', 12.00, 4),
(107, 'Queso Parmesano madurado', 'Gramos', 42.00, 4);

-- 6. Catálogo de Platos del Menú
INSERT INTO Platos_Menu (id_plato, nombre_plato, precio_venta, clasificacion, cantidad_venta, codcategoria) VALUES
(1, 'Cóctel de Camarones', 38000.00, 'Entradas', 208, 1),
(2, 'Carpaccio de Res con Parmesano', 34000.00, 'Entradas', 145, 1),
(3, 'Lomo al Trapo', 68000.00, 'Platos Principales', 342, 2),
(4, 'Risotto de Hongos Silvestres', 52000.00, 'Platos Principales', 187, 2),
(5, 'Medallones en Salsa de Vino Tinto', 64000.00, 'Platos Principales', 160, 2),
(6, 'Copa Vino Malbec Reserva', 24000.00, 'Bebidas', 290, 3),
(7, 'Limonada de Coco Natural', 14000.00, 'Bebidas', 410, 3),
(8, 'Crème Brûlée de Vainilla', 22000.00, 'Postres', 264, 4);

-- 7. Recetas Estándar e Inventario Inicial (Sede 1: Chapinero)
INSERT INTO Recetas (id_plato, id_insumo, cantidad_requerida) VALUES
(3, 101, 350.00),
(1, 102, 200.00),
(4, 103, 180.00),
(4, 104, 120.00),
(4, 107, 40.00),
(8, 106, 150.00);

INSERT INTO Inventario_Sedes (id_sucursal, id_insumo, stock_actual, stock_minimo) VALUES
(1, 101, 15000.00, 3000.00),
(1, 102, 8000.00, 1500.00),
(1, 103, 10000.00, 2000.00),
(1, 104, 5000.00, 1000.00),
(1, 106, 6000.00, 1000.00),
(1, 107, 4000.00, 800.00);

-- ============================================================
-- CAPA DE APLICACIONES: INTELIGENCIA DE NEGOCIOS (DATA WAREHOUSE)
-- ============================================================

-- 20. Tabla de Dimensión: Totales de Ventas por Sede
CREATE TABLE Dim_Ventas_Sede (
    id_sucursal INT PRIMARY KEY,
    total_facturas INT DEFAULT 0,
    monto_total_ventas DECIMAL(14,2) DEFAULT 0.00
);

INSERT INTO Dim_Ventas_Sede (id_sucursal, total_facturas, monto_total_ventas)
SELECT id_sucursal, COUNT(nrofactura) AS total_facturas, IFNULL(SUM(valortotal), 0.00) AS monto_total_ventas
FROM Facturas
GROUP BY id_sucursal;

-- 21. Tabla de Hechos Consolidada para el Dashboard Gerencial (BI Multi-Sede)
CREATE TABLE Hechos_GastroChain_BI (
    id_sucursal INT PRIMARY KEY,
    nombre_sucursal VARCHAR(50),
    total_facturas_emitidas INT,
    ventas_totales_cop DECIMAL(14,2),
    reservas_confirmadas INT,
    FOREIGN KEY (id_sucursal) REFERENCES Sedes(id_sucursal)
);

INSERT INTO Hechos_GastroChain_BI (id_sucursal, nombre_sucursal, total_facturas_emitidas, ventas_totales_cop, reservas_confirmadas)
SELECT s.id_sucursal, s.nombre, IFNULL(d.total_facturas, 0), IFNULL(d.monto_total_ventas, 0.00),
       (SELECT COUNT(*) FROM Reservas r WHERE r.id_sucursal = s.id_sucursal AND r.estado IN ('Confirmada', 'ConfirmadaConAlerta', 'EnCurso')) AS reservas_confirmadas
FROM Sedes s
LEFT JOIN Dim_Ventas_Sede d ON s.id_sucursal = d.id_sucursal;