trigger PassengerTrigger on Passenger__c (
    before insert, 
    before update, 
    before delete,
    after insert, 
    after update, 
    after delete,
    after undelete
) {
    PassengerTriggerHandler handler = new PassengerTriggerHandler();
    handler.run();
}