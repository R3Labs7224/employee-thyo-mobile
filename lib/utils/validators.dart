class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }

  static String? minLength(String? value, int minLength) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    
    if (value.trim().length < minLength) {
      return 'Must be at least $minLength characters';
    }
    
    return null;
  }

  static String? maxLength(String? value, int maxLength) {
    if (value != null && value.trim().length > maxLength) {
      return 'Must not exceed $maxLength characters';
    }
    
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Please enter a valid positive number';
    }
    
    return null;
  }

  static String? employeeCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee code is required';
    }
    
    if (value.trim().length < 3) {
      return 'Employee code must be at least 3 characters';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
}
