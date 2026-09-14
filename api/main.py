from fastapi import FastAPI
from google.cloud import pubsub_v1
import json
import uuid
from datetime import datetime

app = FastAPI()

ID_DEL_PROYECTO = "southern-field-472712-j3"
NOMBRE_DEL_TOPIC = "incidencias"

el_publicador = pubsub_v1.PublisherClient()
ruta_del_topic = el_publicador.topic_path(ID_DEL_PROYECTO, NOMBRE_DEL_TOPIC)


@app.post("/incidencias")
def crear_incidencia(titulo: str, descripcion: str, gravedad: str):
    id_incidencia = str(uuid.uuid4())

    mensaje = {
        "id": id_incidencia,
        "titulo": titulo,
        "descripcion": descripcion,
        "gravedad": gravedad,
        "fecha_de_creacion": datetime.now().isoformat()
    }

    mensaje_adaptado_para_pub_sub = json.dumps(mensaje).encode("utf-8")
    el_publicador.publish(ruta_del_topic, mensaje_adaptado_para_pub_sub)

    return {
        "mensaje": "Incidencia recibida y procesándose...",
        "id": id_incidencia
    }