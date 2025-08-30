public with sharing class BookingEmailServiceInvocable {
    
    public class EmailRequest {
        @InvocableVariable(label='Recipient Email' required=true)
        public String recipientEmail;
        
        @InvocableVariable(label='Last Name' required=true)
        public String lastName;
        
        @InvocableVariable(label='Created Date' required=true)
        public DateTime createdDate;
        
        @InvocableVariable(label='Booking ID' required=true)
        public String bookingId;
    }
    
    @InvocableMethod(label='Send Booking Confirmation Email' description='Sends a booking confirmation email with QR code to the customer')
    public static void sendBookingEmail(List<EmailRequest> requests) {
        for (EmailRequest request : requests) {
            try {
                BookingEmailService.sendBookingConfirmationEmail(
                    request.recipientEmail,
                    request.lastName,
                    request.createdDate,
                    request.bookingId
                );
            } catch (Exception e) {
                System.debug('Error sending email for booking ' + request.bookingId + ': ' + e.getMessage());
            }
        }
    }
}