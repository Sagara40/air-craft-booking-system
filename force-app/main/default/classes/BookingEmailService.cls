/*BookingEmailService*/
public with sharing class BookingEmailService {
    
    public static void sendBookingConfirmationEmail(String recipientEmail, String lastName, DateTime createdDate, String bookingId) {
        try {
            // Generate QR code data
            String qrData = generateQRData(recipientEmail, lastName, createdDate);
            
            // Create email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set recipient
            email.setToAddresses(new String[] { recipientEmail });
            
            // Set email properties
            email.setSubject('Your Booking Confirmation - ' + bookingId);
            email.setSenderDisplayName('Airline Booking System');
            email.setReplyTo('noreply@airline.com');
            
            // Generate HTML email body with card-like UI
            String htmlBody = generateEmailHTML(recipientEmail, lastName, createdDate, bookingId, qrData);
            email.setHtmlBody(htmlBody);
            
            // Send email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            if (results[0].isSuccess()) {
                System.debug('Email sent successfully to: ' + recipientEmail);
            } else {
                System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
                throw new EmailException('Failed to send confirmation email: ' + results[0].getErrors()[0].getMessage());
            }
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            throw new EmailException('Error sending confirmation email: ' + e.getMessage());
        }
    }
    
    private static String generateQRData(String email, String lastName, DateTime createdDate) {
        // Format date to string (YYYYMMDDHHMMSS)
        String dateStr = createdDate.format('yyyyMMddHHmmss');
        
        // Combine data for QR code
        String qrData = email + '|' + lastName + '|' + dateStr;
        
        // Encode for URL safety
        return EncodingUtil.urlEncode(qrData, 'UTF-8');
    }
    
    private static String generateEmailHTML(String email, String lastName, DateTime createdDate, String bookingId, String qrData) {
        String formattedDate = createdDate.format('MMMM dd, yyyy \'at\' h:mm a');
        
        // QR Code API URL (using Google Charts API as example)
        String qrCodeUrl = 'https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=' + qrData;
        
        String htmlBody = '<!DOCTYPE html>' +
            '<html>' +
            '<head>' +
            '<meta charset="UTF-8">' +
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">' +
            '<style>' +
            'body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }' +
            '.email-container { max-width: 600px; margin: 0 auto; }' +
            '.card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); overflow: hidden; }' +
            '.card-header { background: rgba(255, 255, 255, 0.1); padding: 30px; text-align: center; border-bottom: 1px solid rgba(255, 255, 255, 0.2); }' +
            '.airline-logo { color: white; font-size: 32px; font-weight: bold; margin-bottom: 10px; }' +
            '.booking-type { color: rgba(255, 255, 255, 0.9); font-size: 14px; letter-spacing: 2px; text-transform: uppercase; }' +
            '.card-body { padding: 40px; background: white; }' +
            '.passenger-info { margin-bottom: 30px; }' +
            '.info-row { display: table; width: 100%; margin-bottom: 15px; }' +
            '.info-label { display: table-cell; width: 40%; color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; }' +
            '.info-value { display: table-cell; width: 60%; color: #333; font-size: 16px; font-weight: 600; }' +
            '.qr-section { text-align: center; padding: 30px; background: #fafafa; border-radius: 15px; margin-top: 30px; }' +
            '.qr-code { margin: 20px auto; padding: 15px; background: white; display: inline-block; border-radius: 10px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }' +
            '.qr-instructions { color: #666; font-size: 14px; margin-top: 15px; line-height: 1.6; }' +
            '.divider { height: 2px; background: linear-gradient(90deg, transparent, #ddd, transparent); margin: 30px 0; }' +
            '.footer-note { text-align: center; color: #999; font-size: 12px; margin-top: 30px; padding: 20px; }' +
            '.booking-id-badge { display: inline-block; background: #f0f0f0; padding: 8px 16px; border-radius: 20px; font-size: 12px; color: #666; margin-top: 10px; }' +
            '.check-in-button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; border-radius: 30px; text-decoration: none; font-weight: bold; margin-top: 20px; box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3); }' +
            '</style>' +
            '</head>' +
            '<body>' +
            '<div class="email-container">' +
            '<div class="card">' +
            '<div class="card-header">' +
            '<div class="airline-logo">✈️ AIRLINE</div>' +
            '<div class="booking-type">Booking Confirmation</div>' +
            '<div class="booking-id-badge">Booking ID: ' + bookingId + '</div>' +
            '</div>' +
            '<div class="card-body">' +
            '<div class="passenger-info">' +
            '<h2 style="color: #333; margin-bottom: 25px;">Passenger Details</h2>' +
            '<div class="info-row">' +
            '<div class="info-label">Email</div>' +
            '<div class="info-value">' + email + '</div>' +
            '</div>' +
            '<div class="info-row">' +
            '<div class="info-label">Last Name</div>' +
            '<div class="info-value">' + lastName + '</div>' +
            '</div>' +
            '<div class="info-row">' +
            '<div class="info-label">Booking Date</div>' +
            '<div class="info-value">' + formattedDate + '</div>' +
            '</div>' +
            '</div>' +
            '<div class="divider"></div>' +
            '<div class="qr-section">' +
            '<h3 style="color: #333; margin-bottom: 20px;">Your Check-In QR Code</h3>' +
            '<div class="qr-code">' +
            '<img src="' + qrCodeUrl + '" alt="Check-in QR Code" style="display: block;" />' +
            '</div>' +
            '<p class="qr-instructions">' +
            'Present this QR code at the airport check-in counter or self-service kiosk.<br/>' +
            'This code contains your booking information for quick check-in.' +
            '</p>' +
            '</div>' +
            '<div class="divider"></div>' +
            '<div style="text-align: center;">' +
            '<p style="color: #666; margin: 20px 0;">Need to manage your booking?</p>' +
            '<a href="#" class="check-in-button">Online Check-In</a>' +
            '</div>' +
            '</div>' +
            '</div>' +
            '<div class="footer-note">' +
            '<p>This is an automated confirmation email. Please do not reply to this message.</p>' +
            '<p>For assistance, please contact our customer service.</p>' +
            '<p style="margin-top: 15px; color: #bbb;">© 2024 Airline Booking System. All rights reserved.</p>' +
            '</div>' +
            '</div>' +
            '</body>' +
            '</html>';
            
        return htmlBody;
    }
    
    public class EmailException extends Exception {}
}