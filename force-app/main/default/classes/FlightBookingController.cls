public with sharing class FlightBookingController {
    
    @AuraEnabled(cacheable=true)
    public static List<Flight__c> getAllFlights() {
        try {
            return [
                SELECT Id, Name, From_Location__c, To_Location__c, 
                       Depart__c, Passengers_Capacity__c
                FROM Flight__c
                ORDER BY Depart__c DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching flights: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Flight__c getFlightDetails(Id flightId) {
        try {
            return [
                SELECT Id, Name, From_Location__c, To_Location__c, 
                       Depart__c, Passengers_Capacity__c, Seat_Bookings__c
                FROM Flight__c 
                WHERE Id = :flightId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching flight details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getBlockedSeats(Id flightId) {
        try {
            Flight__c flight = [
                SELECT Seat_Bookings__c 
                FROM Flight__c 
                WHERE Id = :flightId
                LIMIT 1
            ];
            
            if (String.isNotBlank(flight.Seat_Bookings__c)) {
                return (List<String>) JSON.deserialize(flight.Seat_Bookings__c, List<String>.class);
            }
            return new List<String>();
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching blocked seats: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String bookSeats(Id flightId, List<PassengerInfo> passengers, List<String> selectedSeats) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Validate passenger count matches seat count
            if (passengers.size() != selectedSeats.size()) {
                throw new AuraHandledException('Number of passengers must match number of selected seats');
            }
            
            // Get current flight and lock for update
            Flight__c flight = [
                SELECT Id, Seat_Bookings__c, Passengers_Capacity__c 
                FROM Flight__c 
                WHERE Id = :flightId
                FOR UPDATE
            ];
            
            // Get current blocked seats
            List<String> blockedSeats = new List<String>();
            if (String.isNotBlank(flight.Seat_Bookings__c)) {
                blockedSeats = (List<String>) JSON.deserialize(flight.Seat_Bookings__c, List<String>.class);
            }
            
            // Check if any selected seat is already blocked
            Set<String> blockedSeatsSet = new Set<String>(blockedSeats);
            for (String seatId : selectedSeats) {
                if (blockedSeatsSet.contains(seatId)) {
                    throw new AuraHandledException('Seat ' + seatId + ' is already booked. Please select different seats.');
                }
            }
            
            // Create passenger records
            List<Passenger__c> passengerRecords = new List<Passenger__c>();
            for (Integer i = 0; i < passengers.size(); i++) {
                PassengerInfo pInfo = passengers[i];
                Passenger__c passenger = new Passenger__c(
                    Flight__c = flightId,
                    Salutation__c = pInfo.salutation,
                    First_Name__c = pInfo.firstName,
                    Last_Name__c = pInfo.lastName,
                    Email__c = pInfo.email,
                    Age__c = pInfo.age,
                    Gender__c = pInfo.gender,
                    Passport_Number__c = pInfo.passportNumber,
                    Seat_Number__c = selectedSeats[i]
                );
                passengerRecords.add(passenger);
            }
            
            insert passengerRecords;
            
            // Update blocked seats on flight
            blockedSeats.addAll(selectedSeats);
            flight.Seat_Bookings__c = JSON.serialize(blockedSeats);
            update flight;
            
            return 'Booking successful! Seats ' + String.join(selectedSeats, ', ') + ' have been reserved.';
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error during booking: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean validateSeatsAvailable(Id flightId, List<String> seatsToCheck) {
        try {
            Flight__c flight = [
                SELECT Seat_Bookings__c 
                FROM Flight__c 
                WHERE Id = :flightId
                LIMIT 1
            ];
            
            if (String.isBlank(flight.Seat_Bookings__c)) {
                return true; // All seats available
            }
            
            List<String> blockedSeats = (List<String>) JSON.deserialize(flight.Seat_Bookings__c, List<String>.class);
            Set<String> blockedSeatsSet = new Set<String>(blockedSeats);
            
            for (String seatId : seatsToCheck) {
                if (blockedSeatsSet.contains(seatId)) {
                    return false;
                }
            }
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error validating seats: ' + e.getMessage());
        }
    }
    
    public class PassengerInfo {
        @AuraEnabled
        public String salutation { get; set; }
        @AuraEnabled
        public String firstName { get; set; }
        @AuraEnabled
        public String lastName { get; set; }
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public Decimal age { get; set; }
        @AuraEnabled
        public String gender { get; set; }
        @AuraEnabled
        public String passportNumber { get; set; }
    }
}