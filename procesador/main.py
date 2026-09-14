from fastapi import FastAPI, Request
from google.cloud import firestore
import json
import base64

app = FastAPI()

bd_firestore = firestore.Client()

@app.post("/procesar")
async def procesar_incidencia(peticion: Request):
    mensaje_recibido = await peticion.json()

    mensaje_en_base64 = mensaje_recibido["message"]["data"]
    json_formato_texto = base64.b64decode(mensaje_en_base64).decode("utf-8")
    incidencia = json.loads(json_formato_texto)

    incidencia["estado"] = "Incidencia procesada"

    bd_firestore.collection("incidencias").document(incidencia["id"]).set(incidencia)

    return {
    "mensaje": "La incidencia se ha procesado y se ha guardado en Firestore",
    "id": incidencia["id"]
    }