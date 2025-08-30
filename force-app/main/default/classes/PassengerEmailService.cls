public with sharing class PassengerEmailService {
    
    public static void sendBookingConfirmationEmail(Passenger__c passenger) {
        if (String.isBlank(passenger.Email__c)) {
            return;
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{passenger.Email__c});
        email.setSubject('✈️ Your Flight Ticket - ' + passenger.Flight__r.Name);
        email.setHtmlBody(generateBookingEmailHTML(passenger));
        email.setSaveAsActivity(false);
        
        if (!Test.isRunningTest()) {
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            } catch (Exception e) {
                System.debug('Error sending booking email: ' + e.getMessage());
            }
        }
    }
    
    public static void sendCheckInConfirmationEmail(Passenger__c passenger) {
        if (String.isBlank(passenger.Email__c)) {
            return;
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{passenger.Email__c});
        email.setSubject('✅ Check-In Confirmed - ' + passenger.Flight__r.Name);
        email.setHtmlBody(generateCheckInEmailHTML(passenger));
        email.setSaveAsActivity(false);
        
        if (!Test.isRunningTest()) {
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            } catch (Exception e) {
                System.debug('Error sending check-in email: ' + e.getMessage());
            }
        }
    }
    
    private static String generateBookingEmailHTML(Passenger__c passenger) {
        String qrCodeUrl = generateQRCodeURL(passenger.QR_Code_Id__c);
        String departureTime = passenger.Flight__r.Departure_Time__c != null ? 
            passenger.Flight__r.Departure_Time__c.format('MMM dd, yyyy h:mm a') : 'TBD';
        
        String html = '<!DOCTYPE html>';
        html += '<html><head>';
        html += '<meta charset="UTF-8">';
        html += '<meta name="viewport" content="width=device-width, initial-scale=1.0">';
        html += '<style>';
        html += 'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }';
        html += '.ticket-container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }';
        html += '.header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }';
        html += '.header h1 { margin: 0; font-size: 28px; font-weight: 600; }';
        html += '.content { padding: 30px; }';
        html += '.flight-info { background: #f8f9fa; border-radius: 8px; padding: 20px; margin-bottom: 30px; }';
        html += '.info-row { display: flex; justify-content: space-between; margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #e0e0e0; }';
        html += '.info-row:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }';
        html += '.info-label { color: #666; font-size: 14px; font-weight: 500; }';
        html += '.info-value { color: #333; font-size: 16px; font-weight: 600; }';
        html += '.qr-section { text-align: center; padding: 30px; background: #fafafa; border-radius: 8px; }';
        html += '.qr-code { background: white; padding: 20px; border-radius: 8px; display: inline-block; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }';
        html += '.qr-title { font-size: 18px; font-weight: 600; margin-bottom: 20px; color: #333; }';
        html += '.qr-instructions { color: #666; font-size: 14px; margin-top: 15px; }';
        html += '.footer { padding: 20px 30px; background: #f8f9fa; text-align: center; color: #666; font-size: 13px; }';
        html += '.important-note { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px; }';
        html += '</style>';
        html += '</head><body>';
        
        html += '<div class="ticket-container">';
        html += '<div class="header">';
        html += '<h1>✈️ Your Flight Ticket</h1>';
        html += '</div>';
        
        html += '<div class="content">';
        html += '<h2 style="color: #333; margin-top: 0;">Hello ' + passenger.First_Name__c + ' ' + passenger.Last_Name__c + ',</h2>';
        html += '<p style="color: #666; line-height: 1.6;">Your flight booking has been confirmed. Please find your ticket details below.</p>';
        
        html += '<div class="flight-info">';
        html += '<div class="info-row">';
        html += '<span class="info-label">Flight Number</span>';
        html += '<span class="info-value">' + passenger.Flight__r.Name + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="info-label">From</span>';
        html += '<span class="info-value">' + (passenger.Flight__r.From_Location__c != null ? passenger.Flight__r.From_Location__c : 'TBD') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="info-label">To</span>';
        html += '<span class="info-value">' + (passenger.Flight__r.To_Location__c != null ? passenger.Flight__r.To_Location__c : 'TBD') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="info-label">Departure</span>';
        html += '<span class="info-value">' + departureTime + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="info-label">Seat</span>';
        html += '<span class="info-value">' + passenger.Seat_Number__c + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="info-label">Passenger</span>';
        html += '<span class="info-value">' + passenger.First_Name__c + ' ' + passenger.Last_Name__c + '</span>';
        html += '</div>';
        html += '</div>';
        
        html += '<div class="qr-section">';
        html += '<div class="qr-title">Your Boarding Pass QR Code</div>';
        html += '<div class="qr-code">';
        html += '<img src="' + qrCodeUrl + '" alt="QR Code" style="width: 250px; height: 250px;">';
        html += '</div>';
        html += '<div class="qr-instructions">Present this QR code at the airport for quick check-in</div>';
        html += '</div>';
        
        html += '<div class="important-note">';
        html += '<strong>Important:</strong> This ticket is valid for one passenger only. ';
        html += 'Please arrive at the airport at least 2 hours before departure for domestic flights and 3 hours for international flights.';
        html += '</div>';
        
        html += '</div>';
        
        html += '<div class="footer">';
        html += 'For support, contact: support@airline.com<br>';
        html += 'QR Code ID: ' + passenger.QR_Code_Id__c + '<br>';
        html += '© 2024 Your Airline. All rights reserved.';
        html += '</div>';
        
        html += '</div>';
        html += '</body></html>';
        
        return html;
    }
    
    private static String generateCheckInEmailHTML(Passenger__c passenger) {
        String qrCodeUrl = generateQRCodeURL(passenger.QR_Code_Id__c);
        String checkInTime = passenger.Check_In_Time__c != null ? 
            passenger.Check_In_Time__c.format('MMM dd, yyyy h:mm a') : 'Just now';
        
        String html = '<!DOCTYPE html>';
        html += '<html><head>';
        html += '<meta charset="UTF-8">';
        html += '<style>';
        html += 'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }';
        html += '.container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }';
        html += '.header { background: linear-gradient(135deg, #56ab2f 0%, #a8e063 100%); color: white; padding: 30px; text-align: center; }';
        html += '.content { padding: 30px; }';
        html += '.success-icon { font-size: 48px; margin-bottom: 10px; }';
        html += '.info-box { background: #f0f8ff; border-radius: 8px; padding: 20px; margin: 20px 0; }';
        html += '</style>';
        html += '</head><body>';
        
        html += '<div class="container">';
        html += '<div class="header">';
        html += '<div class="success-icon">✅</div>';
        html += '<h1 style="margin: 0;">Check-In Confirmed!</h1>';
        html += '</div>';
        
        html += '<div class="content">';
        html += '<p>Dear ' + passenger.First_Name__c + ' ' + passenger.Last_Name__c + ',</p>';
        html += '<p>You have successfully checked in for flight <strong>' + passenger.Flight__r.Name + '</strong>.</p>';
        
        html += '<div class="info-box">';
        html += '<strong>Check-In Details:</strong><br><br>';
        html += 'Seat: <strong>' + passenger.Seat_Number__c + '</strong><br>';
        html += 'Check-In Time: ' + checkInTime + '<br>';
        html += '</div>';
        
        html += '<p style="color: #666;">Please proceed to the gate at least 30 minutes before departure.</p>';
        html += '<p style="color: #666;">Have a pleasant flight!</p>';
        html += '</div>';
        
        html += '</div>';
        html += '</body></html>';
        
        return html;
    }
    
    private static String generateQRCodeURL(String data) {
        // Using QR Server API for QR code generation (free, reliable, no API key needed)
        String encodedData = EncodingUtil.urlEncode(data, 'UTF-8');
        return 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=' + encodedData;
    }
}