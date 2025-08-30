import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBlockedSeats from '@salesforce/apex/FlightBookingController.getBlockedSeats';

export default class BoeingSeatingLayout extends LightningElement {
    @track selectedSeats = [];
    @track hoveredSeat = null;
    @api aircraftModel = 'Boeing 737-800';
    @track showHeatMap = false;
    @api flightId;
    _blockedSeats = [];
    @api maxSelection = 999;

    businessClassRows = [];
    economyPlusRows = [];
    economyClassRows = [];

    seatMap = new Map();
    seatPopularityData = new Map();
    
    @api
    get blockedSeats() {
        return this._blockedSeats;
    }
    
    set blockedSeats(value) {
        this._blockedSeats = value || [];
    }
    
    connectedCallback() {
        this.initializeSeating();
    }

    initializeSeating() {
        this.generateSeatingLayout();
        this.generateMockPopularityData();
        this.updateSeatDisplay();
    }

    generateSeatingLayout() {
        // Clear the seatMap before regenerating
        this.seatMap.clear();
        
        // Boeing 737-800 typical configuration
        // Business Class: 3 rows, 2-2 configuration
        this.businessClassRows = this.generateBusinessClass();
        
        // Economy Plus: 5 rows, 3-3 configuration
        this.economyPlusRows = this.generateEconomyPlus();
        
        // Economy Class: 20 rows, 3-3 configuration
        this.economyClassRows = this.generateEconomyClass();
    }

    generateBusinessClass() {
        const rows = [];
        for (let row = 1; row <= 3; row++) {
            const leftSeats = [];
            const rightSeats = [];
            
            // Left side - A, B
            leftSeats.push(this.createSeat(row, 'A', 'business', 'window'));
            leftSeats.push(this.createSeat(row, 'B', 'business', 'aisle'));
            
            // Right side - C, D
            rightSeats.push(this.createSeat(row, 'C', 'business', 'aisle'));
            rightSeats.push(this.createSeat(row, 'D', 'business', 'window'));
            
            rows.push({
                rowNumber: row,
                leftSeats: this.enhanceSeatsWithComputedProps(leftSeats),
                rightSeats: this.enhanceSeatsWithComputedProps(rightSeats),
                isBusinessClass: true
            });
        }
        return rows;
    }

    generateEconomyPlus() {
        const rows = [];
        for (let row = 4; row <= 8; row++) {
            const leftSeats = [];
            const rightSeats = [];
            
            // Left side - A, B, C
            leftSeats.push(this.createSeat(row, 'A', 'economy-plus', 'window'));
            leftSeats.push(this.createSeat(row, 'B', 'economy-plus', 'middle'));
            leftSeats.push(this.createSeat(row, 'C', 'economy-plus', 'aisle'));
            
            // Right side - D, E, F
            rightSeats.push(this.createSeat(row, 'D', 'economy-plus', 'aisle'));
            rightSeats.push(this.createSeat(row, 'E', 'economy-plus', 'middle'));
            rightSeats.push(this.createSeat(row, 'F', 'economy-plus', 'window'));
            
            rows.push({
                rowNumber: row,
                leftSeats: this.enhanceSeatsWithComputedProps(leftSeats),
                rightSeats: this.enhanceSeatsWithComputedProps(rightSeats),
                isEconomyPlus: true,
                isEmergencyRow: row === 8
            });
        }
        return rows;
    }

    generateEconomyClass() {
        const rows = [];
        for (let row = 9; row <= 28; row++) {
            const leftSeats = [];
            const rightSeats = [];
            
            // Left side - A, B, C
            leftSeats.push(this.createSeat(row, 'A', 'economy', 'window'));
            leftSeats.push(this.createSeat(row, 'B', 'economy', 'middle'));
            leftSeats.push(this.createSeat(row, 'C', 'economy', 'aisle'));
            
            // Right side - D, E, F
            rightSeats.push(this.createSeat(row, 'D', 'economy', 'aisle'));
            rightSeats.push(this.createSeat(row, 'E', 'economy', 'middle'));
            rightSeats.push(this.createSeat(row, 'F', 'economy', 'window'));
            
            rows.push({
                rowNumber: row,
                leftSeats: this.enhanceSeatsWithComputedProps(leftSeats),
                rightSeats: this.enhanceSeatsWithComputedProps(rightSeats),
                isEconomy: true,
                isEmergencyRow: row === 20
            });
        }
        return rows;
    }

    createSeat(row, letter, seatClass, position) {
        const seatId = `${row}${letter}`;
        const isBlocked = this.blockedSeats && this.blockedSeats.includes(seatId);
        const seat = {
            id: seatId,
            row: row,
            letter: letter,
            seatClass: seatClass,
            position: position,
            isAvailable: !isBlocked,
            isSelected: false,
            isEmergencyExit: (row === 8 || row === 20),
            price: this.getSeatPrice(seatClass),
            popularityScore: 0
        };
        
        this.seatMap.set(seatId, seat);
        return seat;
    }

    getSeatPrice(seatClass) {
        const prices = {
            'business': 1200,
            'economy-plus': 350,
            'economy': 200
        };
        return prices[seatClass] || 200;
    }

    handleSeatClick(event) {
        const seatId = event.detail.seatId;
        const seat = this.seatMap.get(seatId);
        
        if (!seat || !seat.isAvailable) {
            return;
        }

        const seatIndex = this.selectedSeats.findIndex(s => s.id === seatId);
        
        if (seatIndex > -1) {
            this.selectedSeats.splice(seatIndex, 1);
            seat.isSelected = false;
        } else {
            // Check max selection limit
            if (this.selectedSeats.length >= this.maxSelection) {
                const event = new ShowToastEvent({
                    title: 'Selection Limit',
                    message: `You can only select ${this.maxSelection} seat(s)`,
                    variant: 'warning'
                });
                this.dispatchEvent(event);
                return;
            }
            this.selectedSeats.push(seat);
            seat.isSelected = true;
        }
        
        this.updateSeatDisplay();
        this.dispatchSeatSelectionEvent();
    }

    handleSeatHover(event) {
        const seatId = event.detail.seatId;
        this.hoveredSeat = this.seatMap.get(seatId);
    }

    handleSeatLeave() {
        this.hoveredSeat = null;
    }

    updateSeatDisplay() {
        // Re-enhance seats with updated computed properties
        this.businessClassRows = this.businessClassRows.map(row => ({
            ...row,
            leftSeats: this.enhanceSeatsWithComputedProps(row.leftSeats),
            rightSeats: this.enhanceSeatsWithComputedProps(row.rightSeats)
        }));
        
        this.economyPlusRows = this.economyPlusRows.map(row => ({
            ...row,
            leftSeats: this.enhanceSeatsWithComputedProps(row.leftSeats),
            rightSeats: this.enhanceSeatsWithComputedProps(row.rightSeats)
        }));
        
        this.economyClassRows = this.economyClassRows.map(row => ({
            ...row,
            leftSeats: this.enhanceSeatsWithComputedProps(row.leftSeats),
            rightSeats: this.enhanceSeatsWithComputedProps(row.rightSeats)
        }));
    }

    dispatchSeatSelectionEvent() {
        const event = new CustomEvent('seatselection', {
            detail: {
                selectedSeats: this.selectedSeats,
                totalPrice: this.selectedSeats.reduce((sum, seat) => sum + seat.price, 0)
            }
        });
        this.dispatchEvent(event);
    }


    generateMockPopularityData() {
        // Generate realistic popularity scores based on common preferences
        this.seatMap.forEach((seat, seatId) => {
            let score = 50; // Base score
            
            // Window seats are most popular
            if (seat.position === 'window') score += 30;
            else if (seat.position === 'aisle') score += 20;
            
            // Business class seats have high popularity
            if (seat.seatClass === 'business') score += 25;
            
            // Front rows are preferred
            if (seat.row <= 5) score += 15;
            else if (seat.row <= 10) score += 10;
            
            // Emergency exit rows are popular for extra legroom
            if (seat.isEmergencyExit) score += 20;
            
            // Middle seats are least popular
            if (seat.position === 'middle') score -= 30;
            
            // Back rows are less popular
            if (seat.row > 20) score -= 15;
            
            // Add some randomness
            score += Math.floor(Math.random() * 20) - 10;
            
            // Ensure score is between 0 and 100
            score = Math.max(0, Math.min(100, score));
            
            seat.popularityScore = score;
            this.seatPopularityData.set(seatId, score);
        });
    }

    toggleHeatMap() {
        this.showHeatMap = !this.showHeatMap;
        this.updateSeatDisplay();
    }

    getHeatMapColor(score) {
        // Convert popularity score (0-100) to color - using purple to yellow gradient
        if (score >= 80) return '#FFD700'; // Gold (most popular)
        if (score >= 60) return '#FFA500'; // Orange
        if (score >= 40) return '#FF69B4'; // Hot pink
        if (score >= 20) return '#9370DB'; // Medium purple
        return '#4B0082'; // Indigo (least popular)
    }


    getSeatClasses(seat) {
        let classes = seat.seatClass;
        
        if (this.showHeatMap && seat.isAvailable) {
            classes += ' heat-map-seat';
        }
        
        return classes;
    }

    enhanceSeatsWithComputedProps(seats) {
        return seats.map(seat => {
            // Get the updated seat data from seatMap
            const updatedSeat = this.seatMap.get(seat.id) || seat;
            return {
                ...updatedSeat,
                computedClass: this.getSeatClasses(updatedSeat),
                heatMapStyle: this.showHeatMap && updatedSeat.isAvailable ? 
                    `background: ${this.getHeatMapColor(updatedSeat.popularityScore)} !important;` : ''
            };
        });
    }

    get heatMapButtonClass() {
        return this.showHeatMap ? 'slds-button slds-button_brand' : 'slds-button slds-button_neutral';
    }
}