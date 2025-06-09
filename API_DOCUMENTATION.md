# API RESTful AlmacénRC - Documentación

## Arquitectura Cliente-Servidor

**SERVIDOR (Backend):**
- **Oracle Database XE 21c**: Puerto 1522
- **Flask API REST**: Puerto 5000
- **Packages PL/SQL**: PKG_PRODUCTOS, PKG_PROVEEDORES, PKG_DIRECTORIO

**CLIENTE (Frontend):**
- **Interfaz Web**: Bootstrap 5 + JavaScript
- **Comunicación**: HTTP/JSON con API REST

---

## Endpoints API REST

### BASE URL
```
http://localhost:5000/api
```

---

### 📦 PRODUCTOS

#### **GET /api/productos**
Obtener todos los productos
```json
Response:
{
  "success": true,
  "data": [
    {
      "id_producto": 600,
      "nombre": "Neumático Michelin 205/60R16",
      "stock": 25,
      "valor_unitario": 120000,
      "fecha_venc": "2025-12-31",
      "iva": 19
    }
  ],
  "total": 21,
  "timestamp": "2024-12-19T10:30:00"
}
```

#### **GET /api/productos/{id}**
Obtener producto específico
```json
Response:
{
  "success": true,
  "data": {
    "id_producto": 600,
    "nombre": "Neumático Michelin 205/60R16",
    "stock": 25,
    "valor_unitario": 120000,
    "fecha_venc": "2025-12-31",
    "iva": 19
  },
  "timestamp": "2024-12-19T10:30:00"
}
```

#### **POST /api/productos**
Crear nuevo producto
```json
Request:
{
  "id_producto": 621,
  "id_marca": 1,
  "nombre": "Batería Varta 60Ah",
  "stock": 15,
  "valor_unitario": 180000,
  "fecha_venc": "2025-06-30",
  "iva": 19
}

Response:
{
  "success": true,
  "message": "Producto creado exitosamente",
  "timestamp": "2024-12-19T10:30:00"
}
```

#### **PUT /api/productos/{id}**
Actualizar producto existente
```json
Request:
{
  "nombre": "Batería Varta 60Ah Premium",
  "stock": 20,
  "valor_unitario": 190000,
  "fecha_venc": "2025-08-31",
  "iva": 19
}

Response:
{
  "success": true,
  "message": "Producto actualizado exitosamente",
  "timestamp": "2024-12-19T10:30:00"
}
```

#### **DELETE /api/productos/{id}**
Eliminar producto
```json
Response:
{
  "success": true,
  "message": "Producto eliminado exitosamente",
  "timestamp": "2024-12-19T10:30:00"
}
```

---

### 🚚 PROVEEDORES

#### **GET /api/proveedores**
Obtener todos los proveedores
```json
Response:
{
  "success": true,
  "data": [
    {
      "codigo": "PROV001",
      "nombre": "AutoPartes Colombia SAS",
      "telefono": "3001234567"
    }
  ],
  "total": 5,
  "timestamp": "2024-12-19T10:30:00"
}
```

#### **POST /api/proveedores**
Crear nuevo proveedor
```json
Request:
{
  "codigo": "PROV006",
  "nombre": "Repuestos Express Ltda",
  "telefono": "3007654321"
}

Response:
{
  "success": true,
  "message": "Proveedor creado exitosamente",
  "timestamp": "2024-12-19T10:30:00"
}
```

---

### 🔗 DIRECTORIO

#### **GET /api/directorio**
Obtener relaciones producto-proveedor
```json
Response:
{
  "success": true,
  "data": [
    {
      "id_producto": 600,
      "producto": "Neumático Michelin 205/60R16",
      "codigo_proveedor": "PROV001",
      "proveedor": "AutoPartes Colombia SAS",
      "stock": 25,
      "valor_unitario": 120000
    }
  ],
  "total": 15,
  "timestamp": "2024-12-19T10:30:00"
}
```

---

## Características RESTful

### ✅ **Criterios Cumplidos**

1. **Arquitectura Cliente-Servidor**: ✅
   - **Cliente**: Interfaz web en Flask (puerto 5000)
   - **Servidor**: Oracle Database + API REST (puerto 1522/5000)

2. **Sin Estado (Stateless)**: ✅
   - Cada request contiene toda la información necesaria
   - No se mantiene estado de sesión en el servidor

3. **Interfaz Uniforme**: ✅
   - URLs descriptivas: `/api/productos`, `/api/proveedores`
   - Métodos HTTP estándar: GET, POST, PUT, DELETE
   - Representación JSON consistente

4. **Sistema de Capas**: ✅
   ```
   CLIENTE WEB ←→ FLASK API ←→ PACKAGES PL/SQL ←→ ORACLE DB
   ```

5. **Cacheable**: ✅
   - Responses incluyen timestamps
   - Datos de solo lectura pueden ser cacheados

6. **Separación Cliente-Servidor**: ✅
   - Frontend y Backend independientes
   - Comunicación solo vía HTTP/JSON

---

## Comandos de Gestión

### **Iniciar Sistema**
```bash
docker-compose up -d
```

### **Ver Estado**
```bash
docker-compose ps
```

### **Ver Logs**
```bash
docker-compose logs flask-web
docker-compose logs oracle-db
```

### **Detener Sistema**
```bash
docker-compose down
```

### **Limpiar Todo**
```bash
docker-compose down --volumes
```

---

## URLs de Acceso

- **API REST**: http://localhost:5000/api
- **Interfaz Web**: http://localhost:5000
- **Oracle Database**: localhost:1522 (usuario: laura/Laura2004)

---

## Ejemplo de Uso con cURL

```bash
# Obtener todos los productos
curl -X GET http://localhost:5000/api/productos

# Obtener producto específico
curl -X GET http://localhost:5000/api/productos/600

# Crear nuevo producto
curl -X POST http://localhost:5000/api/productos \
  -H "Content-Type: application/json" \
  -d '{
    "id_producto": 621,
    "id_marca": 1,
    "nombre": "Batería Varta 60Ah",
    "stock": 15,
    "valor_unitario": 180000,
    "iva": 19
  }'

# Actualizar producto
curl -X PUT http://localhost:5000/api/productos/621 \
  -H "Content-Type: application/json" \
  -d '{
    "stock": 20,
    "valor_unitario": 190000
  }'

# Eliminar producto
curl -X DELETE http://localhost:5000/api/productos/621
```

---

## Estado del Sistema

✅ **COMPLETAMENTE FUNCIONAL**: Arquitectura cliente-servidor RESTful sin dependencias de APEX 