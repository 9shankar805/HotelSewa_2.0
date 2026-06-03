enum UserRole {
  customer,
  hotelOwner,
}

class UserRoleHelper {
  static String roleToString(UserRole role) {
    return role == UserRole.customer ? 'customer' : 'hotel_owner';
  }
  
  static UserRole stringToRole(String? roleString) {
    return roleString == 'hotel_owner' ? UserRole.hotelOwner : UserRole.customer;
  }
}
