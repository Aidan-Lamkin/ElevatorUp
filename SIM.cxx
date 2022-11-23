#include <sstream>
#include <fstream>
#include <vector>
#include <queue>
#include <iostream>
using namespace std;

#include "m.h"

//struct to hold event information
struct Event{
    string type;
    double at;
    int numberOfPeople;
    int floor;
    int elevator;
};

double Uniform(double alpha, double beta, double u){
    return u * beta + alpha;
}

double Random(ifstream randomFile){
    double random = 0.0;
    if(!randomFile.eof()) {
        randomFile >> random;
    }
    else{
        cerr << "Ran out of random numbers" << endl;
        ::exit(1);
    }
    return random;
}

double cdfGeometric(double x){
    return 1.0 - pow(.65, (x + 1.0));
}

double calcGeometricFd(int d, int upper){
    return (cdfGeometric(d) - cdfGeometric(0.0)) / (cdfGeometric(upper) - cdfGeometric(0.0));
}

int getNumberOfPedestrians(double u, int upper){
    int d = (1 + upper) / 2;

    if(calcGeometricFd(d, upper) <= u){
        while(calcGeometricFd(d, upper) <= u){
            d++;
        }
    }
    else if(calcGeometricFd(d-1, upper) > u){
        while(calcGeometricFd(d-1, upper) > u){
            d--;
        }
    }
    else{
        d = 1;
    }

    return d;
}

double cdfExponential(double x){
    return 1 - exp((-x / 10.0));
}

double idfExponential(double u){
    return -10.0 * log(1 - u);
}

double getPedestrianArrivalTime(double u){
    double alpha = cdfExponential(2.0 - 1.0);
    double beta = 1.0 - cdfExponential(90.0);

    double v = Uniform(alpha, 1.0 - beta, u);

    return idfExponential(v);
}


//exponential random variate function
double Exponential(double mew, double u){
    return (-mew * log(1.0 - u));
}

//geometric random variate function
long Geometric(double p, double u){
    return ((long) (log(1.0 - u) / log(p)));
}

//comparison class used for priority queue
class ComparisonClass {
public:
    bool operator() (Event a, Event b) {
        return a.at < b.at;
    }
};



int main( int argc, char* argv[] ){
	int FLOORS;
	int ELEVATORS;
	int DAYS;

	//100 people constant per floor
	int numberOfPeoplePerFloor = 100;
	//argument number 1 is number of floors
	FLOORS = stoi(argv[1]);
	//argument number 2 is number of elevators
	ELEVATORS = stoi(argv[2]);
	//argument number 3 is random file
    ifstream randomFile(argc > 3 ? argv[3] : "/dev/null");
    if(!randomFile){
        cerr << "Error opening random file" << endl;
        ::exit(1);
    }
    //argument 4 is number of days to run simulation
	DAYS = stoi(argv[4]);

    //max number of people that are waiting on elevator across all days
    int MAXQ = 0;

    vector<vector<int> > totalStops = vector<vector<int> >();

    for(int j = 0; j < DAYS; j++) {

        vector<int> peopleRemainingPerFloor = vector<int>();

        for(int i = 0; i < FLOORS; i++){
            peopleRemainingPerFloor.push_back(numberOfPeoplePerFloor);
        }
        int remainingPeople = numberOfPeoplePerFloor * FLOORS;

        //Consistency Check of 1 person 1 floor 1 elevator = 2 stops = Passed

//        peopleRemainingPerFloor.push_back(1);
//        int remainingPeople = 1;

        double t = 0;
        priority_queue <Event, vector<Event>, ComparisonClass> eventList;

        //number of stops in the day including ground floor
        //need to output
        vector<int> STOPS = vector<int>();
        for(int i = 0; i < ELEVATORS; i++){
            STOPS.push_back(0);
        }

        vector<bool> elevatorStatus = vector<bool>();
        for( int i = 0; i < ELEVATORS; i++){
            elevatorStatus.push_back(true);
        }

        double random = 0.0;
        if(!randomFile.eof()) {
            randomFile >> random;
        }
        else{
            cerr << "Ran out of random numbers" << endl;
            ::exit(1);
        }

        Event firstArrival = {"groupArrival", t, getNumberOfPedestrians(random, 8),1,0};
        eventList.push(firstArrival);

        remainingPeople -= firstArrival.numberOfPeople;
        int numberWaiting = 0;

        while (eventList.size() != 0) {
            //get imminent event, pop eventList, update sim time
            Event currentEvent = eventList.top();
            eventList.pop();
            t = currentEvent.at;

            //Event type switch case
            if(currentEvent.type == "groupArrival") {
                cout << "Group Arrived" << endl;
                remainingPeople -= currentEvent.numberOfPeople;

                //schedule next arrival
                int groupSize = currentEvent.numberOfPeople;

                bool available = false;
                int elevatorNumber = 0;
                for (int i = 0; i < elevatorStatus.size(); i++) {
                    if (elevatorStatus[i]) {
                        available = true;
                        elevatorNumber = i + 1;
                        elevatorStatus[i] = false;
                        cout << i + 1 << " busy" << endl;
                        break;
                    }
                }

                if (available) {
                    Event loadUp = {"elevatorLoadUp", t, groupSize, 1, elevatorNumber};
                    eventList.push(loadUp);
                } else {
                    numberWaiting += groupSize;
                }

                if(remainingPeople > 0){

                    double u = 0.0;
                    if(!randomFile.eof()) {
                        randomFile >> u;
                    }
                    else{
                        cerr << "Ran out of random numbers" << endl;
                        ::exit(1);
                    }

                    double v = 0.0;
                    if(!randomFile.eof()) {
                        randomFile >> v;
                    }
                    else{
                        cerr << "Ran out of random numbers" << endl;
                        ::exit(1);
                    }

                    if(remainingPeople < 8){
                        Event nextArrival = {"groupArrival",
                                             t + getPedestrianArrivalTime(v),
                                             getNumberOfPedestrians(u, remainingPeople),
                                             1,
                                             0};
                        eventList.push(nextArrival);
                        cout << "Interarrival time: " << getPedestrianArrivalTime(v) << endl;
                    }
                    else{
                        Event nextArrival = {"groupArrival",
                                             t + getPedestrianArrivalTime(v),
                                             getNumberOfPedestrians(u, 8),
                                             1,
                                             0};
                        eventList.push(nextArrival);
                        cout << "Interarrival time: " << getPedestrianArrivalTime(u) << endl;
                    }
                }

            }

            else if(currentEvent.type == "elevatorLoadUp") {
                cout << "Elevator load up" << endl;

                int groupSize = currentEvent.numberOfPeople;
                vector<int> remainingFloors = vector<int>();
                vector<int> floorCounts = vector<int>();

                //Get available floors
                for(int i = 0; i < peopleRemainingPerFloor.size(); i++){
                    if(peopleRemainingPerFloor[i] != 0){
                        remainingFloors.push_back(i + 1);
                    }
                    floorCounts.push_back(0);
                }


                for (int i = 0; i < groupSize; i++) {
                    double u = 0.0;

                    if(!randomFile.eof()) {
                        randomFile >> u;
                    }
                    else{
                        cerr << "Ran out of random numbers" << endl;
                        ::exit(1);
                    }

                    int selectedFloor = floor(Uniform(0, remainingFloors.size(),u));
                    cout << "Selected Floor" << selectedFloor << endl;
                    floorCounts[selectedFloor]++;

                    peopleRemainingPerFloor[selectedFloor]--;
                    if(peopleRemainingPerFloor[selectedFloor] == 0){
                        remainingFloors.erase(remainingFloors.begin() + selectedFloor);
                    }
                }

                int numberOfStops = 0;
                for(int i = 0; i < floorCounts.size(); i++){
                    if(floorCounts[i] != 0){
                        Event event = {"elevatorUnloadAtFloor", t + numberOfStops, floorCounts[i], i + 1, currentEvent.elevator};
                        eventList.push(event);
                    }
                }
                Event event = {"elevatorReturnToLobby", t + numberOfStops, 0, 0, currentEvent.elevator};
                eventList.push(event);
            }
            else if(currentEvent.type == "elevatorReturnToLobby") {
                cout << "Elevator return" << endl;

                //mark that elevator as available
                int elevatorIndex = currentEvent.elevator - 1;
                elevatorStatus[elevatorIndex] = true;
                cout << elevatorIndex + 1 << " free" << endl;

                STOPS[currentEvent.elevator - 1]++;


                //if people waiting queue up elevatorLoadUp event at same time
                if (numberWaiting > 0) {
                    Event loadUp = {"elevatorLoadUp", t, 0, 1, elevatorIndex + 1};
                    if (numberWaiting < 8) {
                        loadUp.numberOfPeople = numberWaiting;
                        numberWaiting = 0;
                    } else {
                        loadUp.numberOfPeople = 8;
                        numberWaiting -= 8;
                    }
                    eventList.push(loadUp);
                }
            }

            else if(currentEvent.type == "elevatorUnloadAtFloor") {
                cout << "Elevator Unload" << endl;

                int peopleGettingOff = currentEvent.numberOfPeople;
                peopleRemainingPerFloor[currentEvent.floor - 1] -= peopleGettingOff;
                remainingPeople -= peopleGettingOff;
                STOPS[currentEvent.elevator - 1]++;
            }

            //check to see for new maxQ
            if(numberWaiting > MAXQ){
                MAXQ = numberWaiting;
            }


            //check to see if people in queue can enter elevator
            if(numberWaiting > 0) {
                bool available = false;
                int elevatorNumber = 0;
                for (int i = 0; i < elevatorStatus.size(); i++) {
                    if (elevatorStatus[i]) {
                        available = true;
                        elevatorNumber = i + 1;
                        elevatorStatus[i] = false;
                        break;
                    }
                }

                int groupSize = 0;
                if (numberWaiting < 8) {
                    groupSize = numberWaiting;
                    numberWaiting = 0;
                } else {
                    groupSize = 8;
                    numberWaiting -= 8;
                }

                if (available) {
                    Event loadUp = {"elevatorLoadUp", t, groupSize, 1, elevatorNumber};
                    eventList.push(loadUp);
                }
            }

            cout << eventList.size() << endl;
        }

        totalStops.push_back(STOPS);
    }

    //calculate the average stops per elevator per day
    int sum = 0;
    for(int i = 0; i < DAYS; i++){
        for(int j = 0; j < ELEVATORS; j++){
            sum += totalStops[i][j];
        }
    }

    double averageStops = (float)sum / (float)(DAYS * ELEVATORS);

    //OUTPUT Statistics with 5 decimal places worth of precision
    cout << "OUTPUT stops " << averageStops << endl;
    cout << "OUTPUT max qsize " << MAXQ << endl;
    cout << "OUTPUT average delay " << averageStops << endl;
    cout << "OUTPUT stddev delay " << averageStops << endl;

	return 0;
}

