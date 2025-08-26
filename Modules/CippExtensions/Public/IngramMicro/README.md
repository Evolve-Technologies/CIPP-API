# Ingram Micro Integration for CIPP

## Overview
This integration enables CIPP to manage Microsoft 365 licensing through Ingram Micro's Marketplace API, providing similar functionality to the existing Sherweb integration.

## Features
- **Authentication**: Secure OAuth2-based authentication with token caching
- **Customer Management**: List and map Ingram Micro customers to CIPP tenants
- **Product Catalog**: Browse available Microsoft 365 products and SKUs
- **Order Management**: Create new subscriptions and track order status
- **Subscription Management**: View, modify, and cancel existing subscriptions
- **Role-Based Access**: Control which CIPP users can purchase licenses

## Configuration

### Prerequisites
1. Ingram Micro Marketplace API credentials:
   - API Username
   - API Password
   - Subscription Key (X-Subscription-Key)
   - Marketplace Code (e.g., "us")

### Setup Steps
1. Navigate to CIPP Settings > Extensions
2. Find "Ingram Micro" in the list
3. Enable the integration
4. Enter your API credentials:
   - **API Base URL**: `https://api.ingrammicro.com/cmp` (or your regional endpoint)
   - **API Username**: Your Ingram Micro API username
   - **API Password**: Your Ingram Micro API password
   - **Subscription Key**: Your gateway subscription key
   - **Marketplace Code**: Your marketplace identifier (e.g., "us")
5. Configure allowed CIPP roles for license purchasing
6. Save the configuration
7. Test the connection using the "Test" button

### Tenant Mapping
1. After enabling the integration, go to the Mappings section
2. Select Ingram Micro from the dropdown
3. Map each Microsoft 365 tenant to its corresponding Ingram Micro customer
4. Save the mappings

## Usage

### Viewing Current Licenses
1. Navigate to Tenant > Administration > CSP Licenses
2. Select a tenant that has been mapped to an Ingram Micro customer
3. View current subscription details

### Purchasing New Licenses
1. Navigate to Tenant > Administration > Add Subscription
2. Select the tenant
3. Choose from available SKUs
4. Enter the quantity
5. Review the selected SKU details
6. Check the agreement box
7. Submit the order

### Modifying Subscriptions
1. Go to CSP Licenses for the tenant
2. Use the Add/Remove options to adjust quantities
3. Confirm the changes

## API Functions

### Authentication
- `Get-IngramMicroAuthentication`: Handles OAuth2 authentication and token management

### Customer Management
- `Get-IngramMicroCustomers`: Retrieve customer list
- `Set-IngramMicroMapping`: Map tenants to customers
- `Get-IngramMicroMapping`: Retrieve existing mappings

### Catalog & Products
- `Get-IngramMicroCatalog`: Get available products

### Subscriptions
- `Get-IngramMicroCurrentSubscription`: View existing subscriptions
- `Set-IngramMicroSubscription`: Create/modify subscriptions
- `Remove-IngramMicroSubscription`: Cancel subscriptions
- `Get-IngramMicroOrderStatus`: Track order status

### Testing
- `Test-IngramMicroConnection`: Verify API connectivity

## Error Handling
The integration includes comprehensive error handling:
- Authentication failures are logged and reported
- Token refresh is automatic
- API errors are captured and displayed to users
- All actions are logged for troubleshooting

## Security
- API passwords are encrypted using CIPP's secure storage
- Tokens are cached securely with expiration tracking
- Role-based access control for license purchasing
- All API communications use HTTPS

## Troubleshooting

### Connection Issues
1. Verify API credentials are correct
2. Check the API Base URL matches your region
3. Ensure the Subscription Key is valid
4. Test connectivity using the Test button

### Mapping Issues
1. Confirm the tenant exists in both CIPP and Ingram Micro
2. Verify the Ingram Micro customer ID is correct
3. Check that the integration is enabled

### Order Failures
1. Verify the product SKU is available
2. Check customer credit and payment status
3. Ensure order parameters are complete
4. Review error logs for specific issues

## Support
For issues or questions about the Ingram Micro integration:
1. Check CIPP logs for error details
2. Verify API credentials and configuration
3. Contact Ingram Micro support for API-specific issues
4. Report CIPP integration issues on GitHub