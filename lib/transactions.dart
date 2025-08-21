import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'services/fraud_detection_service.dart';
import 'models/transaction_model.dart';
import 'models/risk_assessment_model.dart';
import 'models/fraud_alert_model.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> with TickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService();
  final List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  
  // UI State
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedPlatform = 'All';
  StreamSubscription<FraudAlert>? _fraudAlertsSubscription;
  
  // Animation controllers
  late AnimationController _refreshController;
  
  // Sample mobile money transactions with fraud detection
  final List<Map<String, dynamic>> _sampleTransactions = [
    {
      'id': 'MP001',
      'amount': 45000.0,
      'platform': 'M-Pesa',
      'type': 'send',
      'recipientId': '+255789123456',
      'recipientName': 'John Mwanza',
      'recipientPhone': '+255789123456',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'status': 'completed',
      'metadata': {
        'location': 'Dar es Salaam',
        'device_id': 'device_123',
        'network_type': 'mobile',
        'transaction_fee': 500.0,
        'reference': 'MP001REF',
      },
    },
    {
      'id': 'AM002',
      'amount': 25000.0,
      'platform': 'Airtel Money',
      'type': 'receive',
      'recipientId': 'user_current',
      'recipientName': 'Current User',
      'recipientPhone': '+255712345678',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'metadata': {
        'location': 'Mwanza',
        'device_id': 'device_123',
        'network_type': 'wifi',
        'sender_name': 'Maria Kamau',
        'reference': 'AM002REF',
      },
    },
    {
      'id': 'HP003',
      'amount': 850000.0, // Suspicious high amount
      'platform': 'HaloPesa',
      'type': 'send',
      'recipientId': '+255601234567',
      'recipientName': 'Unknown Contact',
      'recipientPhone': '+255601234567',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'pending',
      'metadata': {
        'location': 'Unknown',
        'device_id': 'device_unknown',
        'network_type': 'vpn',
        'transaction_fee': 8500.0,
        'reference': 'HP003REF',
      },
    },
    {
      'id': 'TP004',
      'amount': 15000.0,
      'platform': 'Tigo Pesa',
      'type': 'pay',
      'recipientId': 'merchant_001',
      'recipientName': 'Shop Mart',
      'recipientPhone': '+255622334455',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
      'metadata': {
        'location': 'Arusha',
        'device_id': 'device_123',
        'network_type': 'mobile',
        'merchant_category': 'retail',
        'reference': 'TP004REF',
      },
    },
    {
      'id': 'MP005',
      'amount': 5000.0,
      'platform': 'M-Pesa',
      'type': 'buy_airtime',
      'recipientId': '+255789123456',
      'recipientName': 'Self',
      'recipientPhone': '+255789123456',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
      'metadata': {
        'location': 'Dar es Salaam',
        'device_id': 'device_123',
        'network_type': 'mobile',
        'airtime_amount': 5000.0,
        'reference': 'MP005REF',
      },
    },
  ];

  // Computed properties
  double get totalBalance => _transactions.fold(0.0, (sum, t) => 
    t.type == 'receive' ? sum + t.amount : sum - t.amount);
  
  double get totalSent => _transactions
    .where((t) => ['send', 'pay', 'withdraw', 'buy_airtime'].contains(t.type))
    .fold(0.0, (sum, t) => sum + t.amount);
  
  double get totalReceived => _transactions
    .where((t) => ['receive', 'deposit'].contains(t.type))
    .fold(0.0, (sum, t) => sum + t.amount);

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _initializeTransactions();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _fraudAlertsSubscription?.cancel();
    super.dispose();
  }

  /// Initialize transactions with fraud detection
  Future<void> _initializeTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize fraud detection service
      await _fraudService.initialize();
      
      // Load sample transactions and analyze them
      for (final sampleData in _sampleTransactions) {
        final transaction = TransactionModel(
          id: sampleData['id'],
          amount: sampleData['amount'],
          platform: sampleData['platform'],
          type: sampleData['type'],
          recipientId: sampleData['recipientId'],
          recipientName: sampleData['recipientName'],
          recipientPhone: sampleData['recipientPhone'],
          timestamp: sampleData['timestamp'],
          status: sampleData['status'],
          metadata: Map<String, dynamic>.from(sampleData['metadata']),
        );
        
        // Analyze transaction for fraud
        await _fraudService.analyzeTransaction(transaction);
        _transactions.add(transaction);
      }
      
      // Listen to fraud alerts
      _fraudAlertsSubscription = _fraudService.fraudAlerts.listen(
        (alert) {
          if (mounted) {
            _showFraudAlert(alert);
          }
        },
      );
      
      _applyFilters();
    } catch (e) {
      debugPrint('Error initializing transactions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Apply filters to transactions
  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Platform filter
        if (_selectedPlatform != 'All' && transaction.platform != _selectedPlatform) {
          return false;
        }
        
        // Status filter
        if (_selectedFilter != 'All') {
          switch (_selectedFilter) {
            case 'Completed':
              return transaction.status == 'completed';
            case 'Pending':
              return transaction.status == 'pending';
            case 'Blocked':
              return transaction.status == 'blocked';
            case 'Suspicious':
              return transaction.isSuspicious;
            default:
              return true;
          }
        }
        
        return true;
      }).toList();
      
      // Sort by timestamp (newest first)
      _filteredTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  /// Show fraud alert
  void _showFraudAlert(FraudAlert alert) {
    final alertType = alert.alertType;
    Color alertColor = Colors.orange;
    IconData alertIcon = Icons.warning;
    
    switch (alertType) {
      case FraudAlertType.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case FraudAlertType.suspicious:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case FraudAlertType.warning:
        alertColor = Colors.amber;
        alertIcon = Icons.info;
        break;
      case FraudAlertType.info:
        alertColor = Colors.blue;
        alertIcon = Icons.info_outline;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(alertIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: alertColor,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () => _showTransactionDetails(alert.transaction),
        ),
      ),
    );
  }

  /// Add new mobile money transaction
  void _addMobileMoneyTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMobileMoneyTransactionSheet(
        onTransactionAdded: (transaction) async {
          // Analyze new transaction for fraud
          await _fraudService.analyzeTransaction(transaction);
          
          setState(() {
            _transactions.insert(0, transaction);
          });
          
          _applyFilters();
        },
      ),
    );
  }

  /// Show transaction details with risk assessment
  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  /// Refresh transactions
  Future<void> _refreshTransactions() async {
    _refreshController.reset();
    _refreshController.forward();
    await _initializeTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mobile Money Security', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addMobileMoneyTransaction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSecurityOverview(),
                _buildFilterChips(),
                _buildTransactionsList(),
              ],
            ),
    );
  }

  /// Build security overview cards
  Widget _buildSecurityOverview() {
    final blockedCount = _transactions.where((t) => t.status == 'blocked').length;
    final suspiciousCount = _transactions.where((t) => t.isSuspicious).length;
    final safeCount = _transactions.length - blockedCount - suspiciousCount;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSecurityCard(
              'Blocked',
              blockedCount.toString(),
              Colors.red,
              Icons.block,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSecurityCard(
              'Suspicious',
              suspiciousCount.toString(),
              Colors.orange,
              Icons.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSecurityCard(
              'Safe',
              safeCount.toString(),
              Colors.green,
              Icons.verified_user,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', _selectedFilter),
                _buildFilterChip('Completed', _selectedFilter),
                _buildFilterChip('Pending', _selectedFilter),
                _buildFilterChip('Blocked', _selectedFilter),
                _buildFilterChip('Suspicious', _selectedFilter),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPlatform = value;
              });
              _applyFilters();
            },
            itemBuilder: (context) => [
              'All',
              'M-Pesa',
              'Airtel Money',
              'HaloPesa',
              'Tigo Pesa',
            ].map((platform) => PopupMenuItem(
              value: platform,
              child: Text(platform),
            )).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _selectedPlatform,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedFilter) {
    final isSelected = label == selectedFilter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Build transactions list
  Widget _buildTransactionsList() {
    return Expanded(
      child: _filteredTransactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return _buildTransactionCard(transaction);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mobile_friendly,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addMobileMoneyTransaction,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual transaction card with risk indicators
  Widget _buildTransactionCard(TransactionModel transaction) {
    final platformColor = Color(transaction.platformColor);
    final isSuspicious = transaction.isSuspicious;
    final isBlocked = transaction.status == 'blocked';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBlocked
              ? Colors.red
              : isSuspicious
                  ? Colors.orange
                  : Colors.transparent,
          width: isBlocked || isSuspicious ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: platformColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        transaction.platform.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: platformColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              transaction.platform,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(transaction.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                transaction.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(transaction.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.typeDisplayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount and risk indicators
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: transaction.type == 'receive'
                              ? Colors.green
                              : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isBlocked || isSuspicious)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isBlocked ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isBlocked ? Icons.block : Icons.warning,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isBlocked ? 'BLOCKED' : 'SUSPICIOUS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Recipient and timestamp
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      transaction.recipientName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    _formatDateTime(transaction.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      case 'failed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Add Mobile Money Transaction Bottom Sheet
class AddMobileMoneyTransactionSheet extends StatefulWidget {
  final Function(TransactionModel) onTransactionAdded;
  
  const AddMobileMoneyTransactionSheet({
    super.key,
    required this.onTransactionAdded,
  });

  @override
  State<AddMobileMoneyTransactionSheet> createState() => _AddMobileMoneyTransactionSheetState();
}

class _AddMobileMoneyTransactionSheetState extends State<AddMobileMoneyTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _selectedPlatform = 'M-Pesa';
  String _selectedType = 'send';
  
  final List<String> _platforms = ['M-Pesa', 'Airtel Money', 'HaloPesa', 'Tigo Pesa'];
  final List<String> _transactionTypes = ['send', 'receive', 'pay', 'withdraw', 'deposit', 'buy_airtime'];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'New Mobile Money Transaction',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Platform selection
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                  items: _platforms.map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getPlatformColor(platform).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                platform.substring(0, 1),
                                style: TextStyle(
                                  color: _getPlatformColor(platform),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(platform),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPlatform = value!),
                ),
                const SizedBox(height: 16),
                
                // Transaction type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _transactionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_formatTransactionType(type)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 16),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (TShs)',
                    border: OutlineInputBorder(),
                    prefixText: 'TShs ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter amount';
                    final amount = double.tryParse(value!);
                    if (amount == null) return 'Please enter valid number';
                    if (amount <= 0) return 'Amount must be greater than zero';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone number
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Phone',
                    border: OutlineInputBorder(),
                    prefixText: '+255',
                    hintText: '789123456',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter phone number';
                    if (value!.length < 9) return 'Please enter valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Recipient name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'm-pesa':
        return const Color(0xFF00A651);
      case 'airtel money':
        return const Color(0xFFE20613);
      case 'halopesa':
        return const Color(0xFF0066CC);
      case 'tigo pesa':
        return const Color(0xFFFF6600);
      default:
        return Colors.purple;
    }
  }
  
  String _formatTransactionType(String type) {
    switch (type) {
      case 'send':
        return 'Send Money';
      case 'receive':
        return 'Receive Money';
      case 'pay':
        return 'Pay Bill';
      case 'withdraw':
        return 'Withdraw Cash';
      case 'deposit':
        return 'Deposit Cash';
      case 'buy_airtime':
        return 'Buy Airtime';
      default:
        return type.toUpperCase();
    }
  }
  
  void _submitTransaction() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final phone = '+255${_phoneController.text}';
      final name = _nameController.text.isEmpty ? null : _nameController.text;
      
      final transaction = TransactionModel(
        id: 'TX${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        platform: _selectedPlatform,
        type: _selectedType,
        recipientId: phone,
        recipientName: name,
        recipientPhone: phone,
        timestamp: DateTime.now(),
        status: 'pending',
        metadata: {
          'location': 'Current Location',
          'device_id': 'current_device',
          'network_type': 'mobile',
          'transaction_fee': _calculateFee(amount),
          'reference': 'TX${DateTime.now().millisecondsSinceEpoch}REF',
        },
      );
      
      widget.onTransactionAdded(transaction);
      Navigator.pop(context);
    }
  }
  
  double _calculateFee(double amount) {
    // Simple fee calculation (in practice this would be platform-specific)
    return amount * 0.01; // 1% fee
  }
}

/// Transaction Details Bottom Sheet with Risk Assessment
class TransactionDetailsSheet extends StatelessWidget {
  final TransactionModel transaction;
  
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(transaction.platformColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transaction.platform.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Color(transaction.platformColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.platform,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      transaction.typeDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Amount
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  transaction.formattedAmount,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(transaction.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Transaction Details
          _buildDetailRow('Transaction ID', transaction.id),
          _buildDetailRow('Recipient', transaction.recipientName ?? 'Unknown'),
          _buildDetailRow('Phone Number', transaction.recipientPhone ?? 'N/A'),
          _buildDetailRow('Timestamp', _formatFullDate(transaction.timestamp)),
          _buildDetailRow('Reference', transaction.metadata['reference'] ?? 'N/A'),
          
          if (transaction.isSuspicious) ..[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This transaction has been flagged as suspicious by our AI fraud detection system.',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // In a real app, this would report the transaction
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction reported for review'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      case 'failed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
