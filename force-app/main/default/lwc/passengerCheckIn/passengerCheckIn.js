import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';
import checkInPassengerByQRCode from '@salesforce/apex/PassengerCheckInController.checkInPassengerByQRCode';
import searchPassengers from '@salesforce/apex/PassengerCheckInController.searchPassengers';
import manualCheckIn from '@salesforce/apex/PassengerCheckInController.manualCheckIn';

export default class PassengerCheckIn extends LightningElement {
    @api recordId; // If placed on a record page
    @track scannedBarcodeValue = '';
    @track isProcessing = false;
    @track passengerResult = null;
    @track searchTerm = '';
    @track searchResults = [];
    @track selectedPassengerId = null;
    @track showManualSearch = false;
    @track scannerAvailable = false;
    
    barcodeScanner;

    // UI state getters
    get hasResult() {
        return this.passengerResult !== null;
    }

    get isSuccess() {
        return this.passengerResult && this.passengerResult.success;
    }

    get isAlreadyCheckedIn() {
        return this.passengerResult && 
               this.passengerResult.passenger && 
               !this.passengerResult.success &&
               this.passengerResult.message && 
               this.passengerResult.message.includes('already checked in');
    }

    get isNotFound() {
        return this.passengerResult && 
               this.passengerResult.passenger === undefined &&
               !this.isProcessing;
    }

    get passengerDetails() {
        return this.passengerResult ? this.passengerResult.passenger : null;
    }

    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get noSearchResults() {
        return this.searchTerm && this.searchResults.length === 0 && !this.isProcessing;
    }

    get showScanButton() {
        return this.scannerAvailable && !this.isProcessing;
    }

    get showManualCheckIn() {
        return this.showManualSearch || this.isNotFound;
    }

    get showPassengerDetails() {
        return this.isSuccess || this.isAlreadyCheckedIn;
    }

    get showSearchResults() {
        return this.searchResults.length > 0;
    }

    get processedSearchResults() {
        return this.searchResults.map(passenger => ({
            ...passenger,
            selectedClass: passenger.isSelected ? 'selected-passenger' : '',
            statusClass: passenger.Check_In_Status__c === 'Checked In' ? 'slds-theme_success' : ''
        }));
    }

    connectedCallback() {
        this.barcodeScanner = getBarcodeScanner();
        if (!this.barcodeScanner || !this.barcodeScanner.isAvailable()) {
            console.log('Barcode scanner is not available on this device');
            this.scannerAvailable = false;
            this.showManualSearch = true;
        } else {
            this.scannerAvailable = true;
        }
    }

    // Start QR scanning using native Salesforce barcode scanner - EXACT COPY from working component
    handleBeginScanClick() {
        const scanningOptions = {
            barcodeTypes: [this.barcodeScanner.barcodeTypes.QR],
            scannerSize: "FULLSCREEN",
            cameraFacing: "BACK",
            showSuccessCheckMark: false, // Don't show checkmark, we'll show our own UI
            enableBulkScan: false,
            enableMultiScan: false
        };

        // Check if BarcodeScanner is available
        if (this.barcodeScanner != null && this.barcodeScanner.isAvailable()) {
            // Start scanning
            this.barcodeScanner
                .scan(scanningOptions)
                .then((results) => {
                    // Handle the scanned barcode(s)
                    if (results && results.length > 0) {
                        // Get the first scanned QR code value
                        this.scannedBarcodeValue = results[0].value;
                        console.log('QR Code scanned:', this.scannedBarcodeValue);
                        // Process the QR code to fetch passenger details
                        this.processQrCode();
                    }
                })
                .catch((error) => {
                    // Handle errors
                    if (error.code === 'USER_DISMISSED') {
                        console.log('User cancelled scanning');
                    } else {
                        console.error('Scanning error:', error);
                        this.showToast('Error', 'Error scanning: ' + error.message, 'error');
                    }
                })
                .finally(() => {
                    // Always dismiss the scanner when done
                    if (this.barcodeScanner) {
                        this.barcodeScanner.dismiss();
                    }
                });
        } else {
            this.showToast('Error', 'Barcode scanner is not available on this device', 'error');
        }
    }

    // Process the QR code value
    processQrCode() {
        if (!this.scannedBarcodeValue) {
            this.showToast('Error', 'No QR code detected', 'error');
            return;
        }

        console.log('Processing QR code:', this.scannedBarcodeValue);
        this.isProcessing = true;
        this.passengerResult = null; // Reset previous scan
        
        checkInPassengerByQRCode({ qrCodeId: this.scannedBarcodeValue })
            .then(result => {
                console.log('Check-in result:', result);
                // Store the result for display
                this.passengerResult = result;
                
                if (result.success) {
                    // Dispatch event to notify parent components of successful check-in
                    this.dispatchEvent(new CustomEvent('checkin', {
                        detail: result
                    }));
                }
            })
            .catch(error => {
                console.error('Check-in error:', error);
                // Create error result for display
                this.passengerResult = {
                    success: false,
                    passenger: null,
                    message: this.reduceErrors(error)
                };
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    handleToggleManualSearch() {
        this.showManualSearch = !this.showManualSearch;
        if (this.showManualSearch) {
            this.resetResults();
        }
    }

    handleSearchInputChange(event) {
        this.searchTerm = event.target.value;
        
        // Debounce search
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            if (this.searchTerm && this.searchTerm.length >= 2) {
                this.performSearch();
            } else {
                this.searchResults = [];
            }
        }, 300);
    }

    performSearch() {
        this.isProcessing = true;
        
        searchPassengers({ searchTerm: this.searchTerm })
            .then(result => {
                this.searchResults = result;
            })
            .catch(error => {
                console.error('Search error:', error);
                this.showToast('Error', 'Failed to search passengers', 'error');
                this.searchResults = [];
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    handlePassengerSelect(event) {
        this.selectedPassengerId = event.currentTarget.dataset.passengerId;
        
        // Highlight selected passenger
        this.searchResults = this.searchResults.map(p => ({
            ...p,
            isSelected: p.Id === this.selectedPassengerId
        }));
    }

    handleManualCheckIn() {
        if (!this.selectedPassengerId) {
            this.showToast('Error', 'Please select a passenger', 'error');
            return;
        }

        this.isProcessing = true;
        
        manualCheckIn({ passengerId: this.selectedPassengerId })
            .then(result => {
                this.passengerResult = result;
                this.searchResults = [];
                this.searchTerm = '';
                this.showManualSearch = false;
                
                if (result.success) {
                    this.showToast('Success', 'Passenger checked in successfully!', 'success');
                    
                    // Fire event for parent components
                    this.dispatchEvent(new CustomEvent('checkin', {
                        detail: {
                            passengerId: result.passenger.Id,
                            passenger: result.passenger
                        }
                    }));
                } else if (this.isAlreadyCheckedIn) {
                    this.showToast('Warning', 'This passenger is already checked in', 'warning');
                } else {
                    this.showToast('Error', result.message || 'Check-in failed', 'error');
                }
            })
            .catch(error => {
                console.error('Manual check-in error:', error);
                this.showToast('Error', 'An error occurred during check-in', 'error');
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    handleReset() {
        this.resetResults();
        this.searchTerm = '';
        this.searchResults = [];
        this.selectedPassengerId = null;
        this.showManualSearch = false;
    }

    resetResults() {
        this.passengerResult = null;
        this.scannedBarcodeValue = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }

        return errors
            .filter(error => !!error)
            .map(error => {
                if (typeof error === 'string') {
                    return error;
                } else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (error.message) {
                    return error.message;
                }
                return JSON.stringify(error);
            })
            .join(', ');
    }
}