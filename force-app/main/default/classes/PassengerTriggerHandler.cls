public with sharing class PassengerTriggerHandler {
    
    public void run() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handleBeforeInsert((List<Passenger__c>)Trigger.new);
            } else if (Trigger.isUpdate) {
                handleBeforeUpdate((List<Passenger__c>)Trigger.new, (Map<Id, Passenger__c>)Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handleAfterInsert((List<Passenger__c>)Trigger.new);
            } else if (Trigger.isUpdate) {
                handleAfterUpdate((List<Passenger__c>)Trigger.new, (Map<Id, Passenger__c>)Trigger.oldMap);
            }
        }
    }
    
    private void handleBeforeInsert(List<Passenger__c> newPassengers) {
        generateQRCodes(newPassengers);
        validatePassengerData(newPassengers);
    }
    
    private void handleBeforeUpdate(List<Passenger__c> newPassengers, Map<Id, Passenger__c> oldPassengerMap) {
        trackCheckInChanges(newPassengers, oldPassengerMap);
    }
    
    private void handleAfterInsert(List<Passenger__c> newPassengers) {
        sendBookingEmails(newPassengers);
    }
    
    private void handleAfterUpdate(List<Passenger__c> newPassengers, Map<Id, Passenger__c> oldPassengerMap) {
        sendCheckInEmails(newPassengers, oldPassengerMap);
    }
    
    private void generateQRCodes(List<Passenger__c> passengers) {
        for (Passenger__c passenger : passengers) {
            if (String.isBlank(passenger.QR_Code_Id__c)) {
                passenger.QR_Code_Id__c = 'PAS-' + DateTime.now().getTime() + '-' + 
                                          String.valueOf(Math.random()).substring(2, 8);
            }
        }
    }
    
    private void validatePassengerData(List<Passenger__c> passengers) {
        for (Passenger__c passenger : passengers) {
            if (String.isBlank(passenger.First_Name__c) || String.isBlank(passenger.Last_Name__c)) {
                passenger.addError('First Name and Last Name are required');
            }
            if (String.isBlank(passenger.Email__c) && String.isBlank(passenger.Phone__c)) {
                passenger.addError('Either Email or Phone is required');
            }
        }
    }
    
    private void trackCheckInChanges(List<Passenger__c> newPassengers, Map<Id, Passenger__c> oldPassengerMap) {
        for (Passenger__c passenger : newPassengers) {
            Passenger__c oldPassenger = oldPassengerMap.get(passenger.Id);
            
            if (passenger.Check_In_Status__c == 'Checked In' && 
                oldPassenger.Check_In_Status__c != 'Checked In' && 
                passenger.Check_In_Time__c == null) {
                passenger.Check_In_Time__c = DateTime.now();
            }
        }
    }
    
    private void sendBookingEmails(List<Passenger__c> passengers) {
        Set<Id> passengerIds = new Set<Id>();
        for (Passenger__c passenger : passengers) {
            if (String.isNotBlank(passenger.Email__c)) {
                passengerIds.add(passenger.Id);
            }
        }
        
        if (!passengerIds.isEmpty()) {
            List<Passenger__c> passengersWithDetails = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Flight__c, 
                       Flight__r.Name, Flight__r.From_Location__c, Flight__r.To_Location__c,
                       Flight__r.Departure_Time__c, Seat_Number__c, QR_Code_Id__c
                FROM Passenger__c
                WHERE Id IN :passengerIds
            ];
            
            for (Passenger__c passenger : passengersWithDetails) {
                PassengerEmailService.sendBookingConfirmationEmail(passenger);
            }
        }
    }
    
    private void sendCheckInEmails(List<Passenger__c> newPassengers, Map<Id, Passenger__c> oldPassengerMap) {
        Set<Id> checkedInPassengerIds = new Set<Id>();
        
        for (Passenger__c passenger : newPassengers) {
            Passenger__c oldPassenger = oldPassengerMap.get(passenger.Id);
            
            if (passenger.Check_In_Status__c == 'Checked In' && 
                oldPassenger.Check_In_Status__c != 'Checked In' &&
                String.isNotBlank(passenger.Email__c)) {
                checkedInPassengerIds.add(passenger.Id);
            }
        }
        
        if (!checkedInPassengerIds.isEmpty()) {
            List<Passenger__c> passengersWithDetails = [
                SELECT Id, First_Name__c, Last_Name__c, Email__c, Flight__c, 
                       Flight__r.Name, Seat_Number__c, Check_In_Time__c, QR_Code_Id__c
                FROM Passenger__c
                WHERE Id IN :checkedInPassengerIds
            ];
            
            for (Passenger__c passenger : passengersWithDetails) {
                PassengerEmailService.sendCheckInConfirmationEmail(passenger);
            }
        }
    }
}