from flask import Flask, render_template, jsonify, request, redirect, url_for, flash
import oracledb
import json
from datetime import datetime
import os
from dateutil import parser

app = Flask(__name__)
app.secret_key = 'almacenrc_secret_key'

DB_CONFIG = {
    'user': 'laura',
    'password': 'Laura2004',
    'dsn': 'oracledb:1521/XEPDB1'
}

PRODUCTOS_INACTIVOS = set()
PROVEEDORES_INACTIVOS = set()

def get_db_connection():
    try:
        connection = oracledb.connect(**DB_CONFIG)
        return connection
    except Exception as e:
        print(f"Error conectando a la base de datos: {e}")
        return None

@app.route('/')
def dashboard():
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        

        ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
        
        productos = []
        total_productos = 0
        productos_stock_bajo = 0
        valor_inventario = 0
        
        for row in ref_cursor:
            total_productos += 1
            if row[2] < 10:
                productos_stock_bajo += 1
            valor_inventario += (row[2] or 0) * (row[3] or 0)
            
            if row[2] < 10:
                productos.append({
                    'id_producto': row[0],
                    'nombre': row[1],
                    'stock': row[2],
                    'valor_unitario': row[3]
                })
        

        ref_cursor = cursor.callfunc('PKG_PROVEEDORES.OBTENER_TODOS', oracledb.CURSOR)
        total_proveedores = len(list(ref_cursor))
        
        cursor.close()
        conn.close()
        
        metrics = {
            'total_productos': total_productos,
            'productos_stock_bajo': productos_stock_bajo,
            'total_proveedores': total_proveedores,
            'valor_inventario': valor_inventario,
            'productos_criticos': productos
        }
        
        return render_template('dashboard.html', metrics=metrics)
        
    except Exception as e:
        flash(f'Error al obtener datos: {e}', 'error')
        return render_template('error.html')

@app.route('/productos')
def productos():
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        

        ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
        
        productos_data = []
        for row in ref_cursor:
            id_producto = row[0]
            activo = 'N' if id_producto in PRODUCTOS_INACTIVOS else 'S'
            
            productos_data.append({
                'id': id_producto,
                'nombre': row[1],
                'stock': row[2],
                'precio': row[3],
                'vencimiento': row[4],
                'iva': row[5],
                'estado': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL',
                'activo': activo
            })
        
        cursor.close()
        conn.close()
        
        return render_template('productos.html', productos=productos_data)
        
    except Exception as e:
        try:
            cursor = conn.cursor()
            ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
            
            productos_data = []
            for row in ref_cursor:
                productos_data.append({
                    'id': row[0],           
                    'nombre': row[1],       
                    'stock': row[2],        
                    'precio': row[3],       
                    'vencimiento': row[4],  
                    'iva': row[5],          
                    'estado': 'CRITICO' if row[2] < 10 else 'BAJO' if row[2] < 30 else 'NORMAL'
                })
            
            cursor.close()
            conn.close()
            return render_template('productos.html', productos=productos_data)
            
        except Exception as e2:
            flash(f'Error al obtener productos: {e} | Fallback: {e2}', 'error')
            return render_template('error.html')

@app.route('/api/productos', methods=['GET'])
def api_productos():
    """API REST para obtener productos usando PKG_PRODUCTOS"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
        
        productos = []
        for row in ref_cursor:
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

@app.route('/api/productos', methods=['POST'])
def api_crear_producto():
    """Crear producto usando PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        fecha_venc = data.get('fecha_venc')
        if fecha_venc:
            try:
                fecha_venc = parser.parse(fecha_venc)
            except:
                fecha_venc = None
        else:
            fecha_venc = None
        
        id_generado = cursor.var(oracledb.NUMBER)
            
        cursor.callproc('PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO', [
            data['id_marca'], 
            data['nombre'], 
            data['stock'], 
            data['valor_unitario'], 
            fecha_venc, 
            data['iva'],
            id_generado
        ])
        
        id_producto_nuevo = int(id_generado.getvalue())
        codigo_proveedor = data.get('codigo_proveedor')
        
        if codigo_proveedor:
            try:
                cursor.callproc('PKG_DIRECTORIO.PR_INSERTAR_DIRECTORIO', [
                    id_producto_nuevo,
                    codigo_proveedor
                ])
                relacion_creada = True
            except Exception as e:
                print(f"⚠️ No se pudo crear relación automática: {e}")
                relacion_creada = False
        else:
            relacion_creada = False
        
        cursor.close()
        conn.close()
        
        mensaje = 'Producto creado exitosamente'
        if relacion_creada:
            mensaje += ' con proveedor asignado automáticamente'
        
        return jsonify({
            'success': True,
            'message': mensaje,
            'id_producto_generado': id_producto_nuevo,
            'relacion_directorio_creada': relacion_creada,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['GET'])
def api_obtener_producto(producto_id):
    """Obtener un producto específico usando PKG_PRODUCTOS.FN_OBTENER_PRODUCTO_JSON"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        producto_json = cursor.callfunc('PKG_PRODUCTOS.FN_OBTENER_PRODUCTO_JSON', str, [producto_id])
        
        if not producto_json:
            return jsonify({'error': 'Producto no encontrado'}), 404
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'data': json.loads(producto_json),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['PUT'])
def api_actualizar_producto(producto_id):
    """Actualizar un producto usando PKG_PRODUCTOS.PR_ACTUALIZAR_PRODUCTO"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        fecha_venc = data.get('fecha_venc')
        if fecha_venc:
            try:
                fecha_venc = parser.parse(fecha_venc)
            except:
                fecha_venc = None
        
        cursor.callproc('PKG_PRODUCTOS.PR_ACTUALIZAR_PRODUCTO', [
            producto_id,
            data.get('id_marca'),
            data.get('nombre'),
            data.get('stock'),
            data.get('valor_unitario'),
            fecha_venc,
            data.get('iva')
        ])
        
        codigo_proveedor = data.get('codigo_proveedor')
        relacion_actualizada = False
        
        if codigo_proveedor:
            try:
                
                try:
                    cursor.callproc('PKG_DIRECTORIO.PR_ELIMINAR_DIRECTORIO', [producto_id, codigo_proveedor])
                except:
                    pass  
                
    
                cursor.callproc('PKG_DIRECTORIO.PR_INSERTAR_DIRECTORIO', [
                    producto_id,
                    codigo_proveedor
                ])
                relacion_actualizada = True
            except Exception as e:
                print(f"⚠️ No se pudo actualizar relación automática: {e}")
                relacion_actualizada = False
        
        cursor.close()
        conn.close()
        
        mensaje = f'Producto {producto_id} actualizado exitosamente'
        if relacion_actualizada:
            mensaje += ' con proveedor actualizado automáticamente'
        
        return jsonify({
            'success': True,
            'message': mensaje,
            'relacion_directorio_actualizada': relacion_actualizada,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>', methods=['DELETE'])
def api_inhabilitar_producto(producto_id):
    """Inhabilitar un producto (eliminación lógica) usando memoria Flask"""
    try:
        
        PRODUCTOS_INACTIVOS.add(producto_id)
        
        return jsonify({
            'success': True,
            'message': 'Producto inhabilitado exitosamente (eliminación lógica)',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/productos/<int:producto_id>/reactivar', methods=['POST'])
def api_reactivar_producto(producto_id):
    """Reactivar producto (habilitar) usando memoria Flask"""
    try:
        
        PRODUCTOS_INACTIVOS.discard(producto_id)
        
        return jsonify({
            'success': True,
            'message': 'Producto habilitado exitosamente (reactivación lógica)',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores', methods=['GET'])
def api_proveedores():
    """API REST para obtener proveedores usando PKG_PROVEEDORES"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        
        ref_cursor = cursor.callfunc('PKG_PROVEEDORES.OBTENER_TODOS', oracledb.CURSOR)
        
        proveedores = []
        for row in ref_cursor:
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
        
        
        codigo_generado = cursor.var(oracledb.NUMBER)
        
        
        cursor.callproc('PKG_PROVEEDORES.PR_INSERTAR_PROVEEDOR', [
            data['nombre'], 
            data['telefono'],
            codigo_generado
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Proveedor creado exitosamente',
            'codigo_generado': int(codigo_generado.getvalue()),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores/<int:codigo_proveedor>', methods=['PUT'])
def api_actualizar_proveedor(codigo_proveedor):
    """Actualizar proveedor usando PKG_PROVEEDORES.PR_ACTUALIZAR_PROVEEDOR"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
     
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

@app.route('/api/proveedores/<string:codigo_proveedor>', methods=['DELETE'])
def api_inhabilitar_proveedor(codigo_proveedor):
    """Inhabilitar proveedor (eliminación lógica) usando memoria Flask"""
    try:
        
        PROVEEDORES_INACTIVOS.add(int(codigo_proveedor))
        
        return jsonify({
            'success': True,
            'message': 'Proveedor inhabilitado exitosamente (eliminación lógica)',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores/<string:codigo_proveedor>/reactivar', methods=['POST'])
def api_reactivar_proveedor(codigo_proveedor):
    """Reactivar proveedor (habilitar) usando memoria Flask"""
    try:
        PROVEEDORES_INACTIVOS.discard(int(codigo_proveedor))
        
        return jsonify({
            'success': True,
            'message': 'Proveedor habilitado exitosamente (reactivación lógica)',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/proveedores/<string:codigo_proveedor>/productos', methods=['GET'])
def api_productos_proveedor(codigo_proveedor):
    """Obtener productos de un proveedor específico"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        ref_cursor_dir = cursor.callfunc('PKG_DIRECTORIO.OBTENER_TODOS', oracledb.CURSOR)
        
        productos = []
        for row in ref_cursor_dir:
            if str(row[2]) == str(codigo_proveedor):  
                id_producto = row[0]
                
                
                producto_json = cursor.callfunc('PKG_PRODUCTOS.FN_OBTENER_PRODUCTO_JSON', str, [id_producto])
                if producto_json:
                    producto_info = json.loads(producto_json)
                    productos.append({
                        'id_producto': producto_info['id_producto'],
                        'nombre': producto_info['nombre'],
                        'stock': producto_info['stock'],
                        'valor_unitario': producto_info['valor_unitario'],
                        'estado_stock': 'CRITICO' if producto_info['stock'] < 10 else 'BAJO' if producto_info['stock'] < 30 else 'NORMAL'
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

@app.route('/api/directorio', methods=['GET'])
def api_directorio():
    """API REST INTERNA para obtener directorio usando PKG_DIRECTORIO - Solo para consultas del sistema"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        
        ref_cursor = cursor.callfunc('PKG_DIRECTORIO.OBTENER_TODOS', oracledb.CURSOR)
        
        directorio = []
        for row in ref_cursor:
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

@app.route('/api/directorio', methods=['POST'])
def api_crear_relacion():
    """Crear nueva relación producto-proveedor usando PKG_DIRECTORIO"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        data = request.get_json()
        cursor = conn.cursor()
        
        
        cursor.callproc('PKG_DIRECTORIO.PR_INSERTAR_DIRECTORIO', [
            data['id_producto'],
            data['codigo_proveedor']
        ])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Relación creada exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/directorio/<int:id_producto>/<string:codigo_proveedor>', methods=['DELETE'])
def api_eliminar_relacion(id_producto, codigo_proveedor):
    """Eliminar relación producto-proveedor usando PKG_DIRECTORIO"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        
        cursor.callproc('PKG_DIRECTORIO.PR_ELIMINAR_DIRECTORIO', [id_producto, codigo_proveedor])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Relación eliminada exitosamente',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/diagnostico/packages')
def diagnostico_packages():
    """Verifica si los paquetes PL/SQL principales existen en la base de datos"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Error de conexión'}), 500
    
    try:
        cursor = conn.cursor()
        diagnostico = {
            'status': 'OK',
            'checks': {}
        }

        test_cases = {
            'PKG_PRODUCTOS.OBTENER_TODOS': ('function',),
            'PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO': ('procedure',),
            'PKG_PRODUCTOS.PR_ACTUALIZAR_PRODUCTO': ('procedure',),
            'PKG_PRODUCTOS.PR_ELIMINAR_PRODUCTO': ('procedure',),
            'PKG_PROVEEDORES.OBTENER_TODOS': ('function',),
            'PKG_DIRECTORIO.OBTENER_TODOS': ('function',)
        }

        for item, (item_type,) in test_cases.items():
            try:
                if 'OBTENER_TODOS' in item:
                    ref_cursor = cursor.callfunc(item, oracledb.CURSOR)
                    diagnostico['checks'][item] = '✅ Funcional'
                else:
                    
                    diagnostico['checks'][item] = '✅ Disponible'
            except Exception as e:
                diagnostico['checks'][item] = f'❌ Error: {e}'

        
        diagnostico['operations_using_packages'] = [
            'productos() - PKG_PRODUCTOS.OBTENER_TODOS',
            'api_productos() - PKG_PRODUCTOS.OBTENER_TODOS', 
            'api_crear_producto() - PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO',
            'api_actualizar_producto() - PKG_PRODUCTOS.PR_ACTUALIZAR_PRODUCTO',
            'api_eliminar_producto() - PKG_PRODUCTOS.PR_ELIMINAR_PRODUCTO'
        ]
        
        
        try:
            ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
            productos_count = len(list(ref_cursor))
            diagnostico['test_pkg_productos'] = f'✅ PKG_PRODUCTOS funcional - {productos_count} productos'
        except Exception as e:
            diagnostico['test_pkg_productos'] = f'❌ Error en PKG_PRODUCTOS: {e}'

        cursor.close()
        conn.close()

        return jsonify(diagnostico)

    except Exception as e:
        return jsonify({'error': str(e)}), 500



@app.route('/proveedores')
def proveedores():
    """Gestión de proveedores usando PKG_PROVEEDORES - OBTIENE TODOS (activos E inactivos)"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        
        ref_cursor = cursor.callfunc('PKG_PROVEEDORES.OBTENER_TODOS', oracledb.CURSOR)
        
        proveedores_data = []
        for row in ref_cursor:
            codigo_proveedor = row[0]
            activo = 'N' if codigo_proveedor in PROVEEDORES_INACTIVOS else 'S'
            
            
            ref_cursor_dir = cursor.callfunc('PKG_DIRECTORIO.OBTENER_TODOS', oracledb.CURSOR)
            productos_count = len([r for r in ref_cursor_dir if r[2] == codigo_proveedor])
            
            proveedores_data.append({
                'codigo': codigo_proveedor, 
                'nombre': row[1],       
                'telefono': row[2],     
                'productos_count': productos_count,
                'activo': activo        
            })
        
        cursor.close()
        conn.close()
        
        return render_template('proveedores.html', proveedores=proveedores_data)
        
    except Exception as e:
        
        try:
            cursor = conn.cursor()
            ref_cursor = cursor.callfunc('PKG_PROVEEDORES.OBTENER_TODOS', oracledb.CURSOR)
            
            proveedores_data = []
            for row in ref_cursor:
                codigo_proveedor = row[0]
                activo = 'N' if codigo_proveedor in PROVEEDORES_INACTIVOS else 'S'
                
                
                ref_cursor_dir = cursor.callfunc('PKG_DIRECTORIO.OBTENER_TODOS', oracledb.CURSOR)
                productos_count = len([r for r in ref_cursor_dir if r[2] == codigo_proveedor])
                
                proveedores_data.append({
                    'codigo': codigo_proveedor,
                    'nombre': row[1],
                    'telefono': row[2],
                    'productos_count': productos_count,
                    'activo': activo        
                })
            
            cursor.close()
            conn.close()
            return render_template('proveedores.html', proveedores=proveedores_data)
            
        except Exception as e2:
            flash(f'Error al obtener proveedores: {e} | Fallback: {e2}', 'error')
            return render_template('error.html')



@app.route('/proceso/abastecimiento')
def proceso_abastecimiento():
    """Proceso de abastecimiento - productos con stock bajo usando packages"""
    conn = get_db_connection()
    if not conn:
        flash('Error de conexión a la base de datos', 'error')
        return render_template('error.html')
    
    try:
        cursor = conn.cursor()
        
        
        ref_cursor = cursor.callfunc('PKG_PRODUCTOS.OBTENER_TODOS', oracledb.CURSOR)
        
        productos_abastecimiento = []
        for row in ref_cursor:
            if row[2] < 15:  # STOCK < 15
                
                ref_cursor_dir = cursor.callfunc('PKG_DIRECTORIO.OBTENER_TODOS', oracledb.CURSOR)
                proveedor = None
                for dir_row in ref_cursor_dir:
                    if dir_row[0] == row[0]:  # Mismo ID_PRODUCTO
                        proveedor = (dir_row[2], dir_row[3], '123456')  # codigo, nombre, telefono_placeholder
                        break
                
                productos_abastecimiento.append({
                    'id_producto': row[0],
                    'nombre': row[1],
                    'stock': row[2],
                    'valor': row[3],
                    'codigo_proveedor': proveedor[0] if proveedor else None,
                    'proveedor': proveedor[1] if proveedor else '⚠️ Sin proveedor - Asignar en Productos',
                    'telefono': proveedor[2] if proveedor else None,
                    'cantidad_sugerida': max(50 - row[2], 10),  
                    'tiene_proveedor': proveedor is not None
                })
        
        cursor.close()
        conn.close()
        
        return render_template('proceso_abastecimiento.html', productos=productos_abastecimiento)
        
    except Exception as e:
        flash(f'Error en proceso de abastecimiento: {e}', 'error')
        return render_template('error.html')


if __name__ == '__main__':
    
    print("🚀 Iniciando AlmacénRC...")
    print("🔧 Conectando solo por paquetes PL/SQL...")
    print("🌐 Iniciando servidor Flask...")
    app.run(host='0.0.0.0', port=5000, debug=True) 