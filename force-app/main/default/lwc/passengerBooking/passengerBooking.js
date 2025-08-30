import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFlightDetails from '@salesforce/apex/FlightBookingController.getFlightDetails';
import getBlockedSeats from '@salesforce/apex/FlightBookingController.getBlockedSeats';
import bookSeats from '@salesforce/apex/FlightBookingController.bookSeats';
import getAllFlights from '@salesforce/apex/FlightBookingController.getAllFlights';

export default class PassengerBooking extends LightningModal {
    @track currentStep = 'flight-selection';
    @track selectedFlightId;
    @track flightDetails = {};
    @track passengerCount = 1;
    @track passengers = [];
    @track selectedSeats = [];
    @track blockedSeats = [];
    @track isLoading = false;
    @track maxSeatsAllowed = 0;
    @track flightOptions = [];
    @track bookingCompleted = false;
    @track showSuccessMessage = false;
    @track flightSearchTerm = '';
    @track showFlightDropdown = false;
    @track filteredFlightOptions = [];
    @track allFlights = [];

    salutationOptions = [
        { label: 'Mr.', value: 'Mr.' },
        { label: 'Ms.', value: 'Ms.' },
        { label: 'Mrs.', value: 'Mrs.' },
        { label: 'Dr.', value: 'Dr.' }
    ];

    genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Other', value: 'Other' }
    ];

    connectedCallback() {
        this.loadFlights();
    }

    loadFlights() {
        getAllFlights()
            .then(result => {
                this.allFlights = result;
                this.flightOptions = result.map(flight => ({
                    label: flight.Name,
                    meta: `${flight.From_Location__c} → ${flight.To_Location__c}`,
                    value: flight.Id,
                    searchString: `${flight.Name} ${flight.From_Location__c} ${flight.To_Location__c}`.toLowerCase()
                }));
                this.filteredFlightOptions = [...this.flightOptions];
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load flights', 'error');
                console.error('Error loading flights:', error);
            });
    }

    get isFlightSelectionStep() {
        return this.currentStep === 'flight-selection';
    }

    get isPassengerDetailsStep() {
        return this.currentStep === 'passenger-details';
    }

    get isSeatSelectionStep() {
        return this.currentStep === 'seat-selection';
    }

    get isConfirmationStep() {
        return this.currentStep === 'confirmation';
    }

    get canAddMorePassengers() {
        return this.passengers.length < this.passengerCount;
    }

    get allPassengersAdded() {
        return this.passengers.length === this.passengerCount && this.passengerCount > 0;
    }

    get canProceedToSeats() {
        return this.allPassengersAdded && this.passengers.every(p => 
            p.firstName && p.lastName && p.age && p.gender && p.passportNumber
        );
    }

    get totalPrice() {
        return this.selectedSeats.reduce((sum, seat) => sum + (seat.price || 0), 0);
    }

    get canConfirmBooking() {
        return this.selectedSeats.length === this.passengerCount;
    }

    get computedComboboxClass() {
        return this.showFlightDropdown ? 
            'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 
            'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    get noFlightsFound() {
        return this.filteredFlightOptions.length === 0 && this.flightSearchTerm;
    }

    handleFlightInputFocus() {
        this.showFlightDropdown = true;
    }

    handleFlightInputBlur() {
        // Delay to allow click on dropdown item
        setTimeout(() => {
            this.showFlightDropdown = false;
        }, 200);
    }

    handleFlightSearch(event) {
        this.flightSearchTerm = event.target.value;
        const searchTerm = this.flightSearchTerm.toLowerCase();
        
        if (searchTerm) {
            this.filteredFlightOptions = this.flightOptions.filter(option => 
                option.searchString.includes(searchTerm)
            );
        } else {
            this.filteredFlightOptions = [...this.flightOptions];
        }
        
        this.showFlightDropdown = true;
    }

    handleFlightSelect(event) {
        const flightId = event.currentTarget.dataset.id;
        const selectedFlight = this.flightOptions.find(option => option.value === flightId);
        
        if (selectedFlight) {
            this.selectedFlightId = flightId;
            this.flightSearchTerm = `${selectedFlight.label} - ${selectedFlight.meta}`;
            this.showFlightDropdown = false;
            this.loadFlightDetails();
        }
    }

    handleFlightSelection(event) {
        this.selectedFlightId = event.detail.value;
        if (this.selectedFlightId) {
            this.loadFlightDetails();
        }
    }

    loadFlightDetails() {
        this.isLoading = true;
        getFlightDetails({ flightId: this.selectedFlightId })
            .then(result => {
                this.flightDetails = result;
                this.maxSeatsAllowed = result.Passengers_Capacity__c || 180;
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load flight details', 'error');
                this.isLoading = false;
            });
    }

    handlePassengerCountChange(event) {
        const count = parseInt(event.target.value, 10);
        if (count > 0 && count <= 10) {
            this.passengerCount = count;
            // Reset passengers array if count changes
            if (this.passengers.length > count) {
                this.passengers = this.passengers.slice(0, count);
            }
        }
    }

    handleAddPassenger() {
        if (this.canAddMorePassengers) {
            this.passengers = [...this.passengers, {
                id: Date.now(),
                salutation: 'Mr.',
                firstName: '',
                lastName: '',
                email: '',
                age: '',
                gender: 'Male',
                passportNumber: ''
            }];
        }
    }

    handlePassengerFieldChange(event) {
        const passengerId = parseInt(event.target.dataset.id, 10);
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.passengers = this.passengers.map(p => {
            if (p.id === passengerId) {
                return { ...p, [field]: value };
            }
            return p;
        });
    }

    handleRemovePassenger(event) {
        const passengerId = parseInt(event.target.dataset.id, 10);
        this.passengers = this.passengers.filter(p => p.id !== passengerId);
    }

    handleNextToPassengerDetails() {
        if (!this.selectedFlightId) {
            this.showToast('Error', 'Please select a flight', 'error');
            return;
        }
        if (this.passengerCount < 1) {
            this.showToast('Error', 'Please enter valid passenger count', 'error');
            return;
        }
        
        // Initialize first passenger if empty
        if (this.passengers.length === 0) {
            this.handleAddPassenger();
        }
        
        this.currentStep = 'passenger-details';
        this.loadBlockedSeats();
    }

    loadBlockedSeats() {
        getBlockedSeats({ flightId: this.selectedFlightId })
            .then(result => {
                this.blockedSeats = result || [];
            })
            .catch(error => {
                console.error('Error loading blocked seats:', error);
            });
    }

    handleNextToSeatSelection() {
        if (!this.canProceedToSeats) {
            this.showToast('Error', 'Please complete all passenger details', 'error');
            return;
        }
        // Reload blocked seats before showing seat selection
        this.loadBlockedSeats();
        this.currentStep = 'seat-selection';
    }

    handleSeatSelection(event) {
        this.selectedSeats = event.detail.selectedSeats;
        
        // Limit selection to passenger count
        if (this.selectedSeats.length > this.passengerCount) {
            this.selectedSeats = this.selectedSeats.slice(0, this.passengerCount);
            this.showToast('Warning', `You can only select ${this.passengerCount} seats`, 'warning');
        }
    }

    handleNextToConfirmation() {
        if (!this.canConfirmBooking) {
            this.showToast('Error', `Please select exactly ${this.passengerCount} seats`, 'error');
            return;
        }
        this.currentStep = 'confirmation';
    }

    handleConfirmBooking() {
        // Prevent double-clicking
        if (this.bookingCompleted || this.isLoading) {
            return;
        }
        
        this.isLoading = true;
        
        const passengerData = this.passengers.map(p => ({
            salutation: p.salutation,
            firstName: p.firstName,
            lastName: p.lastName,
            email: p.email,
            age: parseFloat(p.age),
            gender: p.gender,
            passportNumber: p.passportNumber
        }));

        const seatIds = this.selectedSeats.map(seat => seat.id);

        bookSeats({
            flightId: this.selectedFlightId,
            passengers: passengerData,
            selectedSeats: seatIds
        })
        .then(result => {
            this.bookingCompleted = true;
            this.showSuccessMessage = true;
            this.showToast('Success', result, 'success');
            this.showConfetti();
            
            // Close modal after 3 seconds
            setTimeout(() => {
                this.closeModal();
            }, 3000);
        })
        .catch(error => {
            this.showToast('Error', error.body.message || 'Booking failed', 'error');
            this.isLoading = false;
        });
    }
    
    showConfetti() {
        const colors = ['#f44336', '#e91e63', '#9c27b0', '#673ab7', '#3f51b5', 
                       '#2196f3', '#03a9f4', '#00bcd4', '#009688', '#4caf50',
                       '#8bc34a', '#cddc39', '#ffeb3b', '#ffc107', '#ff9800'];
        
        for (let i = 0; i < 100; i++) {
            setTimeout(() => {
                const confetti = document.createElement('div');
                confetti.className = 'confetti';
                confetti.style.left = Math.random() * 100 + '%';
                confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
                confetti.style.animationDelay = Math.random() * 0.5 + 's';
                document.body.appendChild(confetti);
                
                setTimeout(() => {
                    confetti.remove();
                }, 3500);
            }, i * 30);
        }
    }
    
    closeModal() {
        // Close the modal properly using LightningModal API
        this.close('success');
    }

    handleBack() {
        if (this.currentStep === 'passenger-details') {
            this.currentStep = 'flight-selection';
        } else if (this.currentStep === 'seat-selection') {
            this.currentStep = 'passenger-details';
        } else if (this.currentStep === 'confirmation') {
            this.currentStep = 'seat-selection';
        }
    }

    handleClose() {
        // Close the modal properly using LightningModal API
        this.close('cancelled');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}