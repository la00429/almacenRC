from flask import Flask, render_template, jsonify, request, redirect, url_for, flash
import oracledb
import json
from datetime import datetime
import os

app = Flask(__name__)
app.secret_key = 'almacenrc_secret_key'

# Configuración de la base de datos
DB_CONFIG = {
    'user': 'laura',
    'password': 'Laura2004',
    'dsn': 'oracledb:1521/XEPDB1'  # Usar nombre del servicio Docker correcto
}

def get_db_connection():
    """Obtener conexión a la base de datos Oracle"""
    try:
        connection = oracledb.connect(**DB_CONFIG)
        return connection
    except Exception as e:
        print(f"Error conectando a la base de datos: {e}")
        return None

@app.route('/')
def dashboard():
    """Dashboard principal con métricas"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        # Obtener métricas
        cursor.execute("SELECT COUNT(*) FROM PRODUCTOS")
        total_productos = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM PRODUCTOS WHERE STOCK < 10")
        productos_stock_bajo = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM PROVEEDORES")
        total_proveedores = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(STOCK * VALOR_UNITARIO) FROM PRODUCTOS")
        valor_inventario = cursor.fetchone()[0] or 0
        
        # Productos con stock crítico
        cursor.execute("""
            SELECT ID_PRODUCTO, NOMBRE, STOCK, VALOR_UNITARIO 
            FROM PRODUCTOS 
            WHERE STOCK < 10 
            ORDER BY STOCK ASC
        """)
        productos_criticos = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        metrics = {
            'total_productos': total_productos,
            'productos_stock_bajo': productos_stock_bajo,
            'total_proveedores': total_proveedores,
            'valor_inventario': valor_inventario,
            'productos_criticos': productos_criticos
        }
        
        return render_template('dashboard.html', metrics=metrics)
        
    except Exception as e:
        flash(f'Error al obtener datos: {e}', 'error')
        return render_template('error.html')

@app.route('/productos')
def productos():
    """Gestión de productos usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_PRODUCTOS.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_PRODUCTOS.OBTENER_TODOS', [ref_cursor])
        
        productos_data = []
        for row in ref_cursor.getvalue():
            productos_data.append({
                'id': row[0],           # ID_PRODUCTO
                'nombre': row[1],       # NOMBRE
                'stock': row[2],        # STOCK
                'precio': row[3],       # VALOR_UNITARIO
                'vencimiento': row[4],  # FECHA_VENC
                'iva': row[5],          # IVA
                'estado': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL'
            })
        
        cursor.close()
        conn.close()
        
        return render_template('productos.html', productos=productos_data)
        
    except Exception as e:
        flash(f'Error al obtener productos: {e}', 'error')
        return render_template('error.html')

@app.route('/api/productos', methods=['GET'])
def api_productos():
    """API REST para obtener productos usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_PRODUCTOS.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_PRODUCTOS.OBTENER_TODOS', [ref_cursor])
        
        productos = []
        for row in ref_cursor.getvalue():
            productos.append({
                'id_producto': row[0],
                'nombre': row[1],
                'stock': row[2],
                'valor_unitario': row[3],
                'fecha_venc': row[4],  # Fecha incluida
                'iva': row[5],
                'estado_stock': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL'
            })
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': productos,
            'total': len(productos),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos', methods=['POST'])
def api_crear_producto():
    """Crear producto usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        # Usar package PKG_PRODUCTOS.INSERTAR_PRODUCTO
        fecha_venc = data.get('fecha_venc')
        if fecha_venc == 'N/A' or not fecha_venc:
            fecha_venc = None
            
        cursor.callproc('PKG_PRODUCTOS.INSERTAR_PRODUCTO', [
            data['id_producto'], 
            data['id_marca'], 
            data['nombre'], 
            data['stock'], 
            data['valor_unitario'], 
            fecha_venc, 
            data['iva']
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Producto creado exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['GET'])
def api_obtener_producto(producto_id):
    """Obtener un producto específico por ID usando SQL directo (más confiable)"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Usar SQL directo para consultas individuales (más confiable)
        cursor.execute("""
            SELECT ID_PRODUCTO, NOMBRE, STOCK, VALOR_UNITARIO, 
                   NVL(TO_CHAR(FECHA_VENC, 'YYYY-MM-DD'), 'N/A') as FECHA_VENC, IVA
            FROM PRODUCTOS 
            WHERE ID_PRODUCTO = :1
        """, [producto_id])
        
        row = cursor.fetchone()
        if not row:
            return jsonify({'error': 'Producto no encontrado'}), 404
        
        producto = {
            'id_producto': row[0],
            'nombre': row[1],
            'stock': row[2],
            'valor_unitario': row[3],
            'fecha_venc': row[4] if row[4] != 'N/A' else None,
            'iva': row[5],
            'estado_stock': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL'
        }
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': producto,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['PUT'])
def api_actualizar_producto(producto_id):
    """Actualizar un producto usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        # Usar package PKG_PRODUCTOS.ACTUALIZAR_STOCK
        cursor.callproc('PKG_PRODUCTOS.ACTUALIZAR_STOCK', [
            producto_id,
            data['stock']
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': f'Stock del producto {producto_id} actualizado a {data.get("stock")} unidades',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['DELETE'])
def api_eliminar_producto(producto_id):
    """Eliminar un producto usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_PRODUCTOS.ELIMINAR
        cursor.callproc('PKG_PRODUCTOS.ELIMINAR', [producto_id])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Producto eliminado exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API REST para PROVEEDORES
@app.route('/api/proveedores', methods=['GET'])
def api_proveedores():
    """API REST para obtener proveedores usando PKG_PROVEEDORES"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_PROVEEDORES.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_PROVEEDORES.OBTENER_TODOS', [ref_cursor])
        
        proveedores = []
        for row in ref_cursor.getvalue():
            proveedores.append({
                'codigo': row[0],
                'nombre': row[1],
                'telefono': row[2]
            })
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': proveedores,
            'total': len(proveedores),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores', methods=['POST'])
def api_crear_proveedor():
    """Crear proveedor usando PKG_PROVEEDORES.PR_INSERTAR_PROVEEDOR"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        # Usar package PKG_PROVEEDORES.PR_INSERTAR_PROVEEDOR
        cursor.callproc('PKG_PROVEEDORES.PR_INSERTAR_PROVEEDOR', [
            data['codigo'],
            data['nombre'], 
            data['telefono']
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Proveedor creado exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores/<string:codigo_proveedor>', methods=['GET'])
def api_obtener_proveedor(codigo_proveedor):
    """Obtener un proveedor específico por código"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Consulta directa para obtener proveedor por código
        cursor.execute("""
            SELECT CODIGO_PROVEEDOR, NOMBRE, DIRECCION, TELEFONO, EMAIL
            FROM PROVEEDORES 
            WHERE CODIGO_PROVEEDOR = :1
        """, [codigo_proveedor])
        
        row = cursor.fetchone()
        if not row:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Proveedor no encontrado'}), 404
            
        proveedor = {
            'codigo_proveedor': row[0],
            'nombre': row[1],
            'direccion': row[2],
            'telefono': row[3],
            'email': row[4]
        }
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': proveedor,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores/<string:codigo_proveedor>', methods=['PUT'])
def api_actualizar_proveedor(codigo_proveedor):
    """Actualizar proveedor usando PKG_PROVEEDORES"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        # Usar package PKG_PROVEEDORES.PR_ACTUALIZAR_PROVEEDOR
        cursor.callproc('PKG_PROVEEDORES.PR_ACTUALIZAR_PROVEEDOR', [
            codigo_proveedor,
            data.get('nombre'),
            data.get('telefono')
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Proveedor actualizado exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API REST para DIRECTORIO
@app.route('/api/directorio', methods=['GET'])
def api_directorio():
    """API REST para obtener directorio usando PKG_DIRECTORIO"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_DIRECTORIO.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_DIRECTORIO.OBTENER_TODOS', [ref_cursor])
        
        directorio = []
        for row in ref_cursor.getvalue():
            directorio.append({
                'id_producto': row[0],
                'producto': row[1],
                'codigo_proveedor': row[2],
                'proveedor': row[3]
            })
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': directorio,
            'total': len(directorio),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/proveedores')
def proveedores():
    """Gestión de proveedores usando PKG_PROVEEDORES"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_PROVEEDORES.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_PROVEEDORES.OBTENER_TODOS', [ref_cursor])
        
        proveedores_data = []
        for row in ref_cursor.getvalue():
            # Contar productos usando SQL directo (más eficiente)
            cursor.execute("SELECT COUNT(*) FROM DIRECTORIO WHERE CODIGO = :1", [row[0]])
            productos_count = cursor.fetchone()[0]
            
            proveedores_data.append({
                'codigo': row[0],
                'nombre': row[1],
                'telefono': row[2],
                'productos_count': productos_count
            })
        
        cursor.close()
        conn.close()
        
        return render_template('proveedores.html', proveedores=proveedores_data)
        
    except Exception as e:
        flash(f'Error al obtener proveedores: {e}', 'error')
        return render_template('error.html')

@app.route('/directorio')
def directorio():
    """Gestión del directorio usando PKG_DIRECTORIO"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        # Usar package PKG_DIRECTORIO.OBTENER_TODOS
        ref_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('PKG_DIRECTORIO.OBTENER_TODOS', [ref_cursor])
        
        directorio_data = []
        for row in ref_cursor.getvalue():
            # Obtener stock y precio usando SQL directo
            cursor.execute("SELECT STOCK, VALOR_UNITARIO FROM PRODUCTOS WHERE ID_PRODUCTO = :1", [row[0]])
            producto_info = cursor.fetchone()
            
            directorio_data.append({
                'id_producto': row[0],
                'producto': row[1],
                'codigo_proveedor': row[2],
                'proveedor': row[3],
                'stock': producto_info[0] if producto_info else 0,
                'precio': producto_info[1] if producto_info else 0
            })
        
        cursor.close()
        conn.close()
        
        return render_template('directorio.html', directorio=directorio_data)
        
    except Exception as e:
        flash(f'Error al obtener directorio: {e}', 'error')
        return render_template('error.html')

# Rutas de procesos de negocio
@app.route('/proceso/abastecimiento')
def proceso_abastecimiento():
    """Proceso de abastecimiento - productos con stock bajo usando packages"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        # Productos que necesitan abastecimiento (stock < 15) con proveedores
        cursor.execute("""
            SELECT P.ID_PRODUCTO, P.NOMBRE, P.STOCK, P.VALOR_UNITARIO,
                   PR.CODIGO, PR.NOMBRE AS PROVEEDOR, PR.TELEFONO
            FROM PRODUCTOS P
            LEFT JOIN DIRECTORIO D ON P.ID_PRODUCTO = D.ID_PRODUCTO
            LEFT JOIN PROVEEDORES PR ON D.CODIGO = PR.CODIGO
            WHERE P.STOCK < 15
            ORDER BY P.STOCK ASC, P.NOMBRE
        """)
        
        productos_abastecimiento = []
        for row in cursor.fetchall():
            productos_abastecimiento.append({
                'id_producto': row[0],
                'nombre': row[1],
                'stock': row[2],
                'valor': row[3],
                'codigo_proveedor': row[4],
                'proveedor': row[5] if row[5] else 'Sin proveedor asignado',
                'telefono': row[6],
                'cantidad_sugerida': max(50 - row[2], 10)  # Sugerencia de compra
            })
        
        cursor.close()
        conn.close()
        
        return render_template('proceso_abastecimiento.html', productos=productos_abastecimiento)
        
    except Exception as e:
        flash(f'Error en proceso de abastecimiento: {e}', 'error')
        return render_template('error.html')

# API REST para DIRECTORIO - OPERACIONES ADICIONALES
@app.route('/api/directorio', methods=['POST'])
def api_crear_relacion():
    """Crear nueva relación producto-proveedor"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        # Verificar que el producto existe
        cursor.execute("SELECT ID_PRODUCTO FROM PRODUCTOS WHERE ID_PRODUCTO = :1", [data['id_producto']])
        if not cursor.fetchone():
            return jsonify({'error': 'Producto no encontrado'}), 404
            
        # Verificar que el proveedor existe
        cursor.execute("SELECT CODIGO FROM PROVEEDORES WHERE CODIGO = :1", [data['codigo_proveedor']])
        if not cursor.fetchone():
            return jsonify({'error': 'Proveedor no encontrado'}), 404
        
        # Verificar que la relación no existe ya
        cursor.execute("SELECT 1 FROM DIRECTORIO WHERE ID_PRODUCTO = :1 AND CODIGO = :2", [data['id_producto'], data['codigo_proveedor']])
        if cursor.fetchone():
            return jsonify({'error': 'La relación ya existe'}), 400
        
        # Crear la relación
        cursor.execute("""
            INSERT INTO DIRECTORIO (ID_PRODUCTO, CODIGO)
            VALUES (:1, :2)
        """, [data['id_producto'], data['codigo_proveedor']])
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Relación creada exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/directorio/<int:id_producto>/<int:codigo_proveedor>', methods=['DELETE'])
def api_eliminar_relacion(id_producto, codigo_proveedor):
    """Eliminar relación producto-proveedor"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Verificar que la relación existe
        cursor.execute("SELECT 1 FROM DIRECTORIO WHERE ID_PRODUCTO = :1 AND CODIGO = :2", [id_producto, codigo_proveedor])
        if not cursor.fetchone():
            return jsonify({'error': 'Relación no encontrada'}), 404
        
        # Eliminar la relación
        cursor.execute("DELETE FROM DIRECTORIO WHERE ID_PRODUCTO = :1 AND CODIGO = :2", [id_producto, codigo_proveedor])
        conn.commit()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Relación eliminada exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API REST para obtener productos de un proveedor específico
@app.route('/api/proveedores/<int:codigo>/productos', methods=['GET'])
def api_productos_proveedor(codigo):
    """Obtener productos de un proveedor específico"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT P.ID_PRODUCTO, P.NOMBRE, P.STOCK, P.VALOR_UNITARIO,
                   NVL(TO_CHAR(P.FECHA_VENC, 'YYYY-MM-DD'), 'N/A') as FECHA_VENC, P.IVA
            FROM PRODUCTOS P
            JOIN DIRECTORIO D ON P.ID_PRODUCTO = D.ID_PRODUCTO
            WHERE D.CODIGO = :1
            ORDER BY P.NOMBRE
        """, [codigo])
        
        productos = []
        for row in cursor.fetchall():
            productos.append({
                'id_producto': row[0],
                'nombre': row[1],
                'stock': row[2],
                'valor_unitario': row[3],
                'fecha_venc': row[4],
                'iva': row[5],
                'estado_stock': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL'
            })
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': productos,
            'total': len(productos),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Ruta de diagnóstico para verificar packages
@app.route('/api/diagnostico/packages')
def diagnostico_packages():
    """Verificar estado y uso de packages PL/SQL"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        diagnostico = {
            'packages_status': {},
            'operations_using_packages': [],
            'timestamp': datetime.now().isoformat()
        }
        
        # Verificar estado de packages
        cursor.execute("""
            SELECT object_name, object_type, status 
            FROM user_objects 
            WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
            ORDER BY object_name, object_type
        """)
        
        for row in cursor.fetchall():
            package_name = row[0]
            if package_name not in diagnostico['packages_status']:
                diagnostico['packages_status'][package_name] = {}
            diagnostico['packages_status'][package_name][row[1]] = row[2]
        
        # Listar operaciones que usan packages
        diagnostico['operations_using_packages'] = [
            'productos() - PKG_PRODUCTOS.OBTENER_TODOS',
            'api_productos() - PKG_PRODUCTOS.OBTENER_TODOS', 
            'api_crear_producto() - PKG_PRODUCTOS.INSERTAR_PRODUCTO',
            'api_actualizar_producto() - PKG_PRODUCTOS.ACTUALIZAR_STOCK',
            'api_eliminar_producto() - PKG_PRODUCTOS.ELIMINAR',
            'proveedores() - PKG_PROVEEDORES.OBTENER_TODOS',
            'api_proveedores() - PKG_PROVEEDORES.OBTENER_TODOS',
            'directorio() - PKG_DIRECTORIO.OBTENER_TODOS',
            'api_directorio() - PKG_DIRECTORIO.OBTENER_TODOS'
        ]
        
        # Probar una operación con package
        try:
            ref_cursor = cursor.var(oracledb.CURSOR)
            cursor.callproc('PKG_PRODUCTOS.OBTENER_TODOS', [ref_cursor])
            productos_count = len(list(ref_cursor.getvalue()))
            diagnostico['test_pkg_productos'] = f'✅ PKG_PRODUCTOS funcional - {productos_count} productos'
        except Exception as e:
            diagnostico['test_pkg_productos'] = f'❌ Error en PKG_PRODUCTOS: {str(e)}'
        
        cursor.close()
        conn.close()
        
        return jsonify(diagnostico)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 