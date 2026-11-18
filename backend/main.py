from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import get_db_connection

app = FastAPI(title="GastroChain ERP - API Gateway & Microservicios")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LoginRequest(BaseModel):
    email: str
    password: str

class ReservaRequest(BaseModel):
    nombre_cli: str
    fecha_hora: str
    cantidad: int
    id_sucursal: int

@app.post("/api/login")
def login(datos: LoginRequest):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT e.id_empleado, e.nombre, e.email, e.id_sucursal, r.nombre_rol 
            FROM Empleados e
            JOIN Roles r ON e.id_rol = r.id_rol
            WHERE e.email = %s AND e.password_hash = %s AND e.estado = 'activo'
        """
        cursor.execute(query, (datos.email, datos.password))
        usuario = cursor.fetchone()
        if not usuario:
            raise HTTPException(status_code=401, detail="Credenciales incorrectas o usuario inactivo")
        return {"mensaje": "Login exitoso", "usuario": usuario}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en Login: {str(e)}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.get("/api/platos")
def obtener_platos():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Platos_Menu")
        return cursor.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en Platos_Menu: {str(e)}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.post("/api/reservas")
def crear_reserva(reserva: ReservaRequest):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            INSERT INTO Reservas (nombre_cli, fecha_hora, cantidad, id_sucursal)
            VALUES (%s, %s, %s, %s)
        """
        cursor.execute(query, (reserva.nombre_cli, reserva.fecha_hora, reserva.cantidad, reserva.id_sucursal))
        conn.commit()
        
        id_insertado = cursor.lastrowid
        cursor.execute("SELECT id_reserva, estado FROM Reservas WHERE id_reserva = %s", (id_insertado,))
        resultado = cursor.fetchone()
        return {"mensaje": "Reserva procesada", "detalle": resultado}
    except Exception as e:
        raise HTTPException(status_code=409, detail=str(e))
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.get("/api/bi/resumen")
def obtener_bi():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Hechos_GastroChain_BI")
        return cursor.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en Hechos_GastroChain_BI: {str(e)}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()