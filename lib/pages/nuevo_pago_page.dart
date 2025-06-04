import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/matricula_service.dart';
import '../services/auth_service.dart';

class NuevoPagoPage extends StatefulWidget {
  final List<Map<String, dynamic>> estudiantes;
  final Map<String, dynamic>? estudiantePreseleccionado;

  const NuevoPagoPage({
    super.key,
    required this.estudiantes,
    this.estudiantePreseleccionado,
  });

  @override
  State<NuevoPagoPage> createState() => _NuevoPagoPageState();
}

class _NuevoPagoPageState extends State<NuevoPagoPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');

  Map<String, dynamic>? _estudianteSeleccionado;
  Map<String, dynamic>? _tipoPagoSeleccionado;
  Map<String, dynamic>? _metodoPagoSeleccionado;
  DateTime _fechaPago = DateTime.now();

  List<Map<String, dynamic>> _tiposPago = [];
  List<Map<String, dynamic>> _metodosPago = [];

  bool _isLoading = false;
  bool _datosInicializados = false;

  @override
  void initState() {
    super.initState();
    _estudianteSeleccionado = widget.estudiantePreseleccionado;
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      // PRUEBA: Verificar qué endpoints funcionan realmente
      await MatriculaService.probarEndpointsMatricula();

      final matriculaService = MatriculaService();
      
      // Cargar tipos y métodos de pago en paralelo
      final futures = await Future.wait([
        matriculaService.obtenerTiposPago(token),
        matriculaService.obtenerMetodosPago(token),
      ]);

      setState(() {
        _tiposPago = futures[0];
        _metodosPago = futures[1];
        _datosInicializados = true;
        _isLoading = false;
      });

      // Pre-seleccionar valores por defecto si están disponibles
      if (_tiposPago.isNotEmpty && _tipoPagoSeleccionado == null) {
        // Buscar tipo mensual por defecto
        final mensual = _tiposPago.firstWhere(
          (tipo) => tipo['tipo'] == 'mensual',
          orElse: () => _tiposPago.first,
        );
        setState(() {
          _tipoPagoSeleccionado = mensual;
          _actualizarMontoSugerido();
        });
      }

      if (_metodosPago.isNotEmpty && _metodoPagoSeleccionado == null) {
        setState(() {
          _metodoPagoSeleccionado = _metodosPago.first;
        });
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _actualizarMontoSugerido() {
    if (_tipoPagoSeleccionado != null) {
      double montoSugerido = 0.0;
      
      // Sugerir montos basados en el tipo de pago
      if (_tipoPagoSeleccionado!['tipo'] == 'mensual') {
        montoSugerido = 200.0; // Monto mensual sugerido
      } else if (_tipoPagoSeleccionado!['tipo'] == 'anual') {
        montoSugerido = 2000.0; // Monto anual sugerido (descuento aplicado)
      }
      
      _montoController.text = montoSugerido.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pago de Matrícula'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información...'),
          ],
        ),
      );
    }

    if (!_datosInicializados) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar los datos necesarios'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatosIniciales,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEstudianteSelector(),
            const SizedBox(height: 24),
            _buildTipoPagoSelector(),
            const SizedBox(height: 24),
            _buildMetodoPagoSelector(),
            const SizedBox(height: 24),
            _buildFechaSelector(),
            const SizedBox(height: 24),
            _buildMontoInput(),
            const SizedBox(height: 24),
            _buildDescuentoInput(),
            const SizedBox(height: 24),
            _buildResumen(),
            const SizedBox(height: 32),
            _buildBotonesPago(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudianteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estudiante',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _estudianteSeleccionado,
              hint: const Text('Selecciona un estudiante'),
              isExpanded: true,
              items: widget.estudiantes.map((estudiante) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: estudiante,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.orange[100],
                        child: Text(
                          _getInitials('${estudiante['first_name'] ?? ''} ${estudiante['last_name'] ?? ''}'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${estudiante['first_name'] ?? ''} ${estudiante['last_name'] ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (estudiante['curso'] != null)
                              Text(
                                '${estudiante['curso']['nombre']} - ${estudiante['curso']['turno']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (estudiante) {
                setState(() {
                  _estudianteSeleccionado = estudiante;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoPagoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...(_tiposPago.map((tipo) {
          final isSelected = _tipoPagoSeleccionado?['id'] == tipo['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _tipoPagoSeleccionado = tipo;
                  _actualizarMontoSugerido();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[50] : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.green[300]! : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipo['nombre'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.green[700] : Colors.black,
                            ),
                          ),
                          Text(
                            tipo['tipo'] == 'mensual' 
                              ? 'Pago mensual - Válido por 1 mes'
                              : 'Pago anual - Válido por todo el año académico',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildMetodoPagoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _metodoPagoSeleccionado,
              hint: const Text('Selecciona un método de pago'),
              isExpanded: true,
              items: _metodosPago.map((metodo) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: metodo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metodo['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (metodo['descripcion'] != null && metodo['descripcion'].isNotEmpty)
                        Text(
                          metodo['descripcion'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (metodo) {
                setState(() {
                  _metodoPagoSeleccionado = metodo;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFechaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de Pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: _fechaPago.toString().split(' ')[0]),
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: _fechaPago,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              setState(() {
                _fechaPago = selectedDate;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Selecciona la fecha de pago',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildMontoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monto (Bs.)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Ingresa el monto a pagar',
            prefixText: 'Bs. ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa un monto';
            }
            final monto = double.tryParse(value);
            if (monto == null || monto <= 0) {
              return 'Por favor ingresa un monto válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescuentoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descuento (Bs.) - Opcional',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descuentoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Ingresa el descuento aplicado',
            prefixText: 'Bs. ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final descuento = double.tryParse(value);
              if (descuento == null || descuento < 0) {
                return 'Por favor ingresa un descuento válido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResumen() {
    if (_estudianteSeleccionado == null || _tipoPagoSeleccionado == null) {
      return const SizedBox();
    }

    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final descuento = double.tryParse(_descuentoController.text) ?? 0.0;
    final total = monto - descuento;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          _buildResumenRow('Estudiante:', '${_estudianteSeleccionado!['first_name'] ?? ''} ${_estudianteSeleccionado!['last_name'] ?? ''}'.trim()),
          _buildResumenRow('Tipo de pago:', _tipoPagoSeleccionado!['nombre']),
          if (_metodoPagoSeleccionado != null)
            _buildResumenRow('Método de pago:', _metodoPagoSeleccionado!['nombre']),
          _buildResumenRow('Fecha de pago:', _fechaPago.toString().split(' ')[0]),
          const Divider(),
          _buildResumenRow('Monto:', 'Bs. ${monto.toStringAsFixed(2)}'),
          if (descuento > 0)
            _buildResumenRow('Descuento:', '- Bs. ${descuento.toStringAsFixed(2)}', color: Colors.green),
          const Divider(),
          _buildResumenRow(
            'Total a pagar:', 
            'Bs. ${total.toStringAsFixed(2)}', 
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? (isTotal ? Colors.blue[700] : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesPago() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _procesarPago,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Procesar Pago',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String nombreCompleto) {
    final words = nombreCompleto.split(' ');
    String initials = '';
    for (int i = 0; i < words.length && i < 2; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0];
      }
    }
    return initials.isEmpty ? 'E' : initials.toUpperCase();
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_estudianteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un estudiante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_metodoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      final monto = double.parse(_montoController.text);
      final descuento = double.tryParse(_descuentoController.text) ?? 0.0;

      await MatriculaService().crearMatricula(
        estudianteId: _estudianteSeleccionado!['id'],
        tipoPagoId: _tipoPagoSeleccionado!['id'],
        metodoPagoId: _metodoPagoSeleccionado!['id'],
        monto: monto,
        descuento: descuento,
        token: token,
      );

      setState(() {
        _isLoading = false;
      });

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago procesado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Volver a la página anterior
      Navigator.of(context).pop();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Extraer mensaje específico del error del backend
      String mensajeError = 'Error desconocido al procesar el pago';
      
      if (e.toString().contains('ApiError')) {
        // Es un error del backend, intentar extraer el mensaje específico
        final errorString = e.toString();
        print('🔍 Error completo: $errorString');
        
        // Buscar patrones de mensaje de error común del backend
        if (errorString.contains('matrícula ANUAL vigente')) {
          mensajeError = 'El estudiante ya tiene una matrícula anual vigente. No es necesario realizar otro pago hasta el próximo año académico.';
        } else if (errorString.contains('matrícula MENSUAL vigente')) {
          mensajeError = 'El estudiante ya tiene una matrícula mensual vigente. Espera a que venza para realizar el próximo pago.';
        } else if (errorString.contains('Status: 400')) {
          mensajeError = 'Los datos proporcionados no son válidos. Verifica la información e intenta nuevamente.';
        } else if (errorString.contains('Status: 401')) {
          mensajeError = 'No tienes autorización para realizar esta operación. Inicia sesión nuevamente.';
        } else if (errorString.contains('Status: 403')) {
          mensajeError = 'No tienes permisos para realizar pagos de matrícula.';
        } else if (errorString.contains('Status: 500')) {
          mensajeError = 'Error interno del servidor. Contacta al administrador del sistema.';
        } else {
          mensajeError = 'Error de conexión con el servidor. Verifica tu conexión a internet.';
        }
      } else {
        mensajeError = e.toString().replaceAll('Exception: ', '');
      }

      // Mostrar diálogo con el error detallado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Error al procesar pago'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensajeError,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Sugerencia:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Revisa el historial de pagos para ver las matrículas existentes\n'
                      '• Si es un pago anual, estás cubierto todo el año académico\n'
                      '• Para dudas, contacta a la administración',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ver Historial'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a página anterior
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }
} 