bool canReadCatalog(String role) => role != 'visitor' ? true : false;
bool canReserve(String role) => role == 'user' || role == 'admin';
bool isAdmin(String role) => role == 'admin';
