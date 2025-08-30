public with sharing class PassengerCheckInController {
    
    @AuraEnabled
    public static CheckInResult checkInPassengerByQRCode(String qrCodeId) {
        CheckInResult result = new CheckInResult();
        
        try {
            if (String.isBlank(qrCodeId)) {
                result.success = false;
                result.message = 'Invalid QR code';
                return result;
            }
            
            List<Passenger__c> passengers = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                       Check_In_Status__c, Check_In_Time__c, QR_Code_Id__c,
                       Flight__c, Flight__r.Name, Seat_Number__c
                FROM Passenger__c 
                WHERE QR_Code_Id__c = :qrCodeId
                LIMIT 1
            ];
            
            if (passengers.isEmpty()) {
                result.success = false;
                result.message = 'Passenger not found';
                return result;
            }
            
            Passenger__c passenger = passengers[0];
            
            if (passenger.Check_In_Status__c == 'Checked In') {
                result.success = false;
                result.passenger = passenger;
                result.message = 'Passenger is already checked in';
                return result;
            }
            
            passenger.Check_In_Status__c = 'Checked In';
            passenger.Check_In_Time__c = DateTime.now();
            
            System.debug('Before update - Check_In_Status__c: ' + passenger.Check_In_Status__c);
            System.debug('Before update - Check_In_Time__c: ' + passenger.Check_In_Time__c);
            
            update passenger;
            
            passenger = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                       Check_In_Status__c, Check_In_Time__c, QR_Code_Id__c,
                       Flight__c, Flight__r.Name, Seat_Number__c
                FROM Passenger__c 
                WHERE Id = :passenger.Id
            ];
            
            System.debug('After update - Check_In_Status__c: ' + passenger.Check_In_Status__c);
            System.debug('After update - Check_In_Time__c: ' + passenger.Check_In_Time__c);
            
            result.success = true;
            result.passenger = passenger;
            result.message = 'Check-in successful';
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error during check-in: ' + e.getMessage();
        }
        
        return result;
    }
    
    @AuraEnabled
    public static List<Passenger__c> searchPassengers(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<Passenger__c>();
        }
        
        String searchPattern = '%' + searchTerm + '%';
        
        return [
            SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                   Check_In_Status__c, Check_In_Time__c, QR_Code_Id__c,
                   Flight__c, Flight__r.Name, Seat_Number__c
            FROM Passenger__c
            WHERE First_Name__c LIKE :searchPattern
               OR Last_Name__c LIKE :searchPattern
               OR Email__c LIKE :searchPattern
               OR Phone__c LIKE :searchPattern
            ORDER BY Last_Name__c, First_Name__c
            LIMIT 50
        ];
    }
    
    @AuraEnabled
    public static CheckInResult manualCheckIn(String passengerId) {
        CheckInResult result = new CheckInResult();
        
        try {
            if (String.isBlank(passengerId)) {
                result.success = false;
                result.message = 'Invalid passenger ID';
                return result;
            }
            
            List<Passenger__c> passengers = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                       Check_In_Status__c, Check_In_Time__c, QR_Code_Id__c,
                       Flight__c, Flight__r.Name, Seat_Number__c
                FROM Passenger__c 
                WHERE Id = :passengerId
                LIMIT 1
            ];
            
            if (passengers.isEmpty()) {
                result.success = false;
                result.message = 'Passenger not found';
                return result;
            }
            
            Passenger__c passenger = passengers[0];
            
            if (passenger.Check_In_Status__c == 'Checked In') {
                result.success = false;
                result.passenger = passenger;
                result.message = 'Passenger is already checked in';
                return result;
            }
            
            passenger.Check_In_Status__c = 'Checked In';
            passenger.Check_In_Time__c = DateTime.now();
            
            System.debug('Before update - Check_In_Status__c: ' + passenger.Check_In_Status__c);
            System.debug('Before update - Check_In_Time__c: ' + passenger.Check_In_Time__c);
            
            update passenger;
            
            passenger = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                       Check_In_Status__c, Check_In_Time__c, QR_Code_Id__c,
                       Flight__c, Flight__r.Name, Seat_Number__c
                FROM Passenger__c 
                WHERE Id = :passenger.Id
            ];
            
            System.debug('After update - Check_In_Status__c: ' + passenger.Check_In_Status__c);
            System.debug('After update - Check_In_Time__c: ' + passenger.Check_In_Time__c);
            
            result.success = true;
            result.passenger = passenger;
            result.message = 'Check-in successful';
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error during check-in: ' + e.getMessage();
        }
        
        return result;
    }
    
    public class CheckInResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Passenger__c passenger;
        @AuraEnabled public String message;
        
        public CheckInResult() {
            this.success = false;
            this.passenger = null;
            this.message = '';
        }
    }
}