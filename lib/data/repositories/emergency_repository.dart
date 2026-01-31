import '../models/api_response_model.dart';
import '../models/emergency_contact_model.dart';
import '../services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Emergency/SOS Repository
class EmergencyRepository {
  final ApiService _apiService = ApiService();

  /// Get all emergency contacts
  Future<ApiResponse<List<EmergencyContactModel>>> getContacts() async {
    final response = await _apiService.get<List<dynamic>>(
      ApiEndpoints.emergencyContacts,
    );

    if (response.success && response.data != null) {
      final contacts = (response.data as List)
          .map((json) => EmergencyContactModel.fromJson(json))
          .toList();
      return ApiResponse.success(data: contacts);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to get contacts',
      statusCode: response.statusCode,
    );
  }

  /// Add emergency contact
  Future<ApiResponse<EmergencyContactModel>> addContact({
    required String name,
    required String email,
    required String role,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.addEmergencyContact,
      body: {
        'name': name,
        'email': email,
        'role': role,
      },
    );

    if (response.success && response.data != null) {
      final contact = EmergencyContactModel.fromJson(response.data!);
      return ApiResponse.success(data: contact);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to add contact',
      statusCode: response.statusCode,
    );
  }

  /// Delete emergency contact
  Future<ApiResponse<void>> deleteContact(String contactId) async {
    final response = await _apiService.delete(
      '${ApiEndpoints.deleteEmergencyContact}/$contactId',
    );

    if (response.success) {
      return ApiResponse.success();
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to delete contact',
      statusCode: response.statusCode,
    );
  }

  /// Send SOS alert
  Future<ApiResponse<void>> sendSosAlert({
    required double latitude,
    required double longitude,
    String? message,
    List<String>? contactIds,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.sendSosAlert,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (message != null) 'message': message,
        if (contactIds != null) 'contact_ids': contactIds,
      },
    );

    if (response.success) {
      return ApiResponse.success(message: 'SOS alert sent successfully');
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to send SOS alert',
      statusCode: response.statusCode,
    );
  }

  /// Get SOS history
  Future<ApiResponse<List<Map<String, dynamic>>>> getSosHistory() async {
    final response = await _apiService.get<List<dynamic>>(
      ApiEndpoints.sosHistory,
    );

    if (response.success && response.data != null) {
      final history = (response.data as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      return ApiResponse.success(data: history);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to get SOS history',
      statusCode: response.statusCode,
    );
  }
}
