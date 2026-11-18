const API_URL = "http://127.0.0.1:8000";

// 1. Al cargar la página, intenta sincronizar datos reales desde MySQL
document.addEventListener("DOMContentLoaded", async () => {
    console.log("🚀 GastroChain Frontend conectado a app.js");
    await cargarDatosInicialesDesdeMySQL();
});

async function cargarDatosInicialesDesdeMySQL() {
    try {
        // Traer datos BI para actualizar los KPIs del Dashboard si el backend responde
        const resBI = await fetch(`${API_URL}/api/bi/resumen`);
        if (resBI.ok) {
            const datosBI = await resBI.json();
            console.log("📊 Resumen BI recibido de MySQL:", datosBI);
            // Aquí puedes actualizar tarjetas del DOM si tu endpoint devuelve totales
        }
    } catch (error) {
        console.warn("⚠️ Backend no disponible o sin conexión en /api/bi/resumen:", error);
    }
}

// 2. CONECTAR FORMULARIO DE LOGIN REAL CON FASTAPI (/api/login)
window.handleLoginSubmit = async function(e) {
    e.preventDefault();
    const email = document.getElementById("loginEmail").value;
    const password = document.getElementById("loginPass").value;

    try {
        const respuesta = await fetch(`${API_URL}/api/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: email, password: password })
        });

        const data = await respuesta.json();

       if (respuesta.ok) {
            const usuario = data.usuario || {};
            const rolBD = (usuario.nombre_rol || "").toLowerCase().replace("ñ", "n").trim();

            let rolUI = "mesero";
            if (rolBD.includes("dueno") || rolBD.includes("admin")) rolUI = "dueño";
            else if (rolBD.includes("gerente")) rolUI = "gerente";
            else if (rolBD.includes("cocina")) rolUI = "cocina";
            else if (rolBD.includes("cajero") || rolBD.includes("caja")) rolUI = "cajero";

            quickLogin(rolUI);

            // Actualizar nombre real, iniciales y cargo exacto desde MySQL
            if (usuario.nombre) {
                document.getElementById("userName").innerText = usuario.nombre;
                const iniciales = usuario.nombre.split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase();
                document.getElementById("userAvatar").innerText = iniciales;
            }
            if (usuario.nombre_rol) {
                document.getElementById("userRoleBadge").innerText = usuario.nombre_rol;
            }

            console.log("✅ Sesión iniciada contra MySQL:", usuario);
        }else {
            alert("❌ Error de acceso: " + (data.detail || "Credenciales inválidas"));
        }
    } catch (error) {
        console.error("❌ Error conectando con /api/login:", error);
        alert("No se pudo conectar con el servidor FastAPI (verifica que uvicorn esté corriendo).");
    }
};

// 3. CONECTAR FORMULARIO DE RESERVAS CON FASTAPI (/api/reservas)
window.handleReservationSubmit = async function(e) {
    e.preventDefault();

    const client = document.getElementById("resClientName").value;
    const branchName = document.getElementById("resBranch").value;
    const datetime = document.getElementById("resDateTime").value;
    const guests = parseInt(document.getElementById("resGuests").value);
    const table = document.getElementById("resTable").value;

    // Mapear nombre de sucursal al ID en MySQL
    const branchIdMap = {
        "Chapinero": 1,
        "Zona Rosa": 2,
        "Usaquén": 3
    };
    const idSucursal = branchIdMap[branchName] || 1;

    // Formatear fecha para MySQL (YYYY-MM-DD HH:MM:SS)
    const fechaFormateada = datetime ? datetime.replace("T", " ") + ":00" : "2026-11-20 20:00:00";

    // Calcular resumen de platos pre-ordenados
    let dishSummary = [];
    let totalVal = 0;
    if (dishQuantities.lomo > 0) { dishSummary.push(`${dishQuantities.lomo}x Lomo`); totalVal += dishQuantities.lomo * dishPrices.lomo; }
    if (dishQuantities.coctel > 0) { dishSummary.push(`${dishQuantities.coctel}x Cóctel`); totalVal += dishQuantities.coctel * dishPrices.coctel; }
    if (dishQuantities.vino > 0) { dishSummary.push(`${dishQuantities.vino}x Vino`); totalVal += dishQuantities.vino * dishPrices.vino; }
    if (dishQuantities.risotto > 0) { dishSummary.push(`${dishQuantities.risotto}x Risotto`); totalVal += dishQuantities.risotto * dishPrices.risotto; }

    try {
        // Enviar reserva a FastAPI -> MySQL
        const respuesta = await fetch(`${API_URL}/api/reservas`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                nombre_cli: client,
                fecha_hora: fechaFormateada,
                cantidad: guests,
                id_sucursal: idSucursal
            })
        });

        const resultado = await respuesta.json();

        if (respuesta.ok) {
            // Agregar también a la lista visual en pantalla
            const newRes = {
                id: `R-${resultado.detalle?.id_reserva || Math.floor(1000 + Math.random() * 9000)}`,
                client: client,
                branch: branchName,
                datetime: fechaFormateada.slice(0, 16),
                guests: guests,
                table: table,
                dishes: dishSummary.join(", ") || "Sin pre-orden",
                total: `$${totalVal.toLocaleString("es-CO")} COP`,
                status: resultado.detalle?.estado || "Confirmada"
            };

            reservationsData.unshift(newRes);
            renderReservationsList();

            // Limpiar formulario
            document.getElementById("resClientName").value = "";
            document.getElementById("resTable").value = "";
            dishQuantities = { lomo: 0, coctel: 0, vino: 0, risotto: 0 };
            ["lomo", "coctel", "vino", "risotto"].forEach(d => {
                document.getElementById(`qty-${d}`).innerText = "0";
            });
            calculateSubtotal();

            alert("✅ Reserva guardada en MySQL correctamente.");
        } else {
            alert("⚠️ No se pudo guardar la reserva: " + (resultado.detail || "Error en servidor"));
        }
    } catch (error) {
        console.error("❌ Error enviando reserva a FastAPI:", error);
        alert("Error de red al intentar guardar la reserva en el backend.");
    }
};