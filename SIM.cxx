#include <sstream>
#include <fstream>
#include <vector>
#include <queue>
#include <iostream>
#include <cmath>
#include <iomanip>
#include <thread>
#include <cassert>
using namespace std;

class RandomFile{
    public:
        ifstream r;
        RandomFile(string filename){
            r = ifstream(filename, std::ifstream::in);
            if(!r){
                cerr << "Error opening random file" << endl;
                ::exit(1);
            }
        }
        double getU(){
            double u = 0.0;
            if(!r.eof()) {
                r >> u;
            }
            else{
                cerr << "Ran out of random numbers" << endl;
                ::exit(1);
            }
            return u;
        }
        ~RandomFile(){
            r.close();
        }
};

//struct to hold event information
struct Event{
    //type of event
    string type;
    //activation time
    double at;
    //number of people in event
    int numberOfPeople;
    //what floor the event is happening on
    int floor;
    //which elevator the event is using
    int elevator;

    bool operator<( const Event& rhs ) const {
        // .at is activation time of the event
        if( this->at == rhs.at) {
            return this->type < rhs.type;
        }
        // inverted! we want the least // activation time to have
        // higher priority
        return !( this->at < rhs.at );
    }
};

//struct to hold person
struct Person{
    double at;
    int desiredFloor;
};

double Uniform(double alpha, double beta, double u){
    return alpha + (beta - alpha) * u;
}

long Equilikely(double alpha, double beta, double u){
    return (alpha + (long)((beta - alpha + 1) * u));
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
    else if(calcGeometricFd(1, upper) <= u){
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
    return -10.0 * log(1.0 - u);
}

double getPedestrianArrivalTime(double u){
    double alpha = cdfExponential(2.0);
    double F90 = cdfExponential(90.0);

    double v = Uniform(alpha, F90, u);

    return idfExponential(v);
}

double getElevatorTime(int h){
    if(h == 1){
        return 8.0;
    }
    else if(h > 1){
        return (16 + 5 * (h - 2));
    }
}

double getLoadTime(int nPassengers){
    if(nPassengers == 1){
        return 3;
    }
    else if(nPassengers < 10){
        return 3 + 2*(nPassengers - 1);
    }
    else{
        return 22;
    }
}

class Floor{
    public:
        int floorNumber;
        int capacity = 100;
};

class Welford{
    public:
        int i = 0;
        double xibar = 0.0;
        double vi = 0.0;

        void addDataPoint(double xi){
            double diff = xi - xibar;
            i++;
            vi = vi + ((i - 1) / (double)i) * pow(diff, 2);
            xibar = xibar + (1 / (double)i) * diff;
        }

        double getStandardDeviation(){
            return sqrt(vi / i);
        }
};

void runSim(Welford &w, RandomFile &r, int numFLOORS, int ELEVATORS, int &MAXQ, int &numStops, vector<int> optimalTimes, int d){
    //initialize simulation clock to 0
        double t = 0;

        int FLOORS = numFLOORS;

        //initialize empty event list
        priority_queue <Event, vector<Event> > eventList = priority_queue <Event, vector<Event> >();

        vector<bool> elevatorStatus = vector<bool>();
        for( int i = 0; i < ELEVATORS; i++){
            elevatorStatus.push_back(true);
        }

        double random = r.getU();
        double u = r.getU();


        //initialize elevators to have nobody in them
        vector<vector<Person> >elevatorLoads = vector<vector<Person> >();
        for(int i = 0; i < ELEVATORS; i++){
            elevatorLoads.push_back(vector<Person>());
        }

        //initalize first group arrival
        Event firstArrival = {"groupArrival", getPedestrianArrivalTime(u), getNumberOfPedestrians(random, 8),0,0};
        eventList.push(firstArrival);

        queue <Person> pedestrianQueue = queue<Person>();

        vector<Floor> availableFloors;
        for(int i = 0; i < FLOORS;i++){
            Floor temp;
            temp.floorNumber = i + 1;
            availableFloors.push_back(temp);
        }

        int remainingPeople = 100 * FLOORS;

        while (!eventList.empty()) {
            //get imminent event, pop eventList, update sim time
            Event currentEvent = eventList.top();
            eventList.pop();
            t = currentEvent.at;

            assert(remainingPeople >= 0);

            //Event type switch case
            if(currentEvent.type == "groupArrival") {
                cout << "Group of " << currentEvent.numberOfPeople << " Arrived at time " << currentEvent.at << endl;

                //Get size of group
                int groupSize = currentEvent.numberOfPeople;
                remainingPeople -= groupSize;

                //Create person struct for each person in group
                //Assign at as currentEvent.at and choose their desired floor
                for(int i = 0; i < groupSize; i++){
                    
                    double u = r.getU();

                    int destFloor = Equilikely(0, FLOORS - 1, u);
                    int selectedFloor = availableFloors[destFloor].floorNumber;

                    availableFloors[destFloor].capacity--;

                    if(availableFloors[destFloor].capacity == 0){
                        Floor temp = availableFloors[destFloor];
                        availableFloors[destFloor] = availableFloors[--FLOORS];
                        availableFloors[FLOORS] = temp;
                    }

                    pedestrianQueue.push({t, selectedFloor});
                }

                cout << "Remaining People " << remainingPeople << endl;
        
                //Schedule next arrival if people still remaining
                if(remainingPeople > 0){

                    double u = r.getU();
                    double v = r.getU();

                    if(remainingPeople < 8){
                        Event nextArrival = {"groupArrival",
                                             t + getPedestrianArrivalTime(v),
                                             getNumberOfPedestrians(u, remainingPeople),
                                             0,
                                             0};
                        eventList.push(nextArrival);
                    }
                    else{
                        Event nextArrival = {"groupArrival",
                                             t + getPedestrianArrivalTime(v),
                                             getNumberOfPedestrians(u, 8),
                                             0,
                                             0};
                        eventList.push(nextArrival);
                    }
                }
            }
            else if(currentEvent.type == "elevatorUnloadAtFloor") {
                //log message
                cout << "Elevator " << currentEvent.elevator << " unloaded " << currentEvent.numberOfPeople << " at floor " << currentEvent.floor << " at " << currentEvent.at<< endl;

                //decrease remaining people for this floor by amout of people getting off
                int peopleGettingOff = currentEvent.numberOfPeople;

                vector<Person> group;
                for(int i = 0; i < elevatorLoads[currentEvent.elevator - 1].size(); i++){
                    if(elevatorLoads[currentEvent.elevator - 1][i].desiredFloor == currentEvent.floor){
                        group.push_back(elevatorLoads[currentEvent.elevator - 1][i]);
                    }
                }
                int unloadTime = getLoadTime(peopleGettingOff);
                //delay data
                for(int k = 0; k < group.size(); k++){
                    double delayTime = (double)((t + unloadTime - group[k].at) - optimalTimes[currentEvent.floor - 1]) / (double)optimalTimes[currentEvent.floor - 1];
                    w.addDataPoint(delayTime);
                    cout << "Delay Time: " << delayTime << " unload time " << unloadTime << " arrival time " << group[k].at << " optimal time " << optimalTimes[currentEvent.floor - 1] << " sim time " << t << endl;
                }

                //remove people getting off for this elevator
                int index = 0;
                while(index != elevatorLoads[currentEvent.elevator - 1].size()){
                    if(elevatorLoads[currentEvent.elevator - 1][index].desiredFloor == currentEvent.floor){
                        elevatorLoads[currentEvent.elevator - 1].erase(elevatorLoads[currentEvent.elevator - 1].begin() + index);
                    }
                    else{
                        index++;
                    }
                }

                //If elevator still has people on it schedule next drop off else schedule return
                if(elevatorLoads[currentEvent.elevator - 1].size() != 0){
                    //find next floor
                    int nextFloor = 9999;
                    for(int i = 0; i < elevatorLoads[currentEvent.elevator - 1].size(); i++){
                        if(elevatorLoads[currentEvent.elevator - 1][i].desiredFloor < nextFloor){
                            nextFloor = elevatorLoads[currentEvent.elevator - 1][i].desiredFloor;
                        }
                    }

                    //Compute distance and calculate time for next drop off
                    //see how many people are going to each floor
                    int nextGroup = 0;
                    vector<Person> group;
                    for(int i = 0; i < elevatorLoads[currentEvent.elevator - 1].size(); i++){
                        if(elevatorLoads[currentEvent.elevator - 1][i].desiredFloor == nextFloor){
                            nextGroup++;
                            group.push_back(elevatorLoads[currentEvent.elevator - 1][i]);
                        }
                    }

                    assert(currentEvent.floor < nextFloor);
                    //schedule next drop off
                    int totalElevatorTime;
                    int unloadTime = getLoadTime(peopleGettingOff);
                    totalElevatorTime = getLoadTime(peopleGettingOff) + getElevatorTime(nextFloor - currentEvent.floor);
                    Event unload = {"elevatorUnloadAtFloor", t + totalElevatorTime, nextGroup, nextFloor, currentEvent.elevator};
                    eventList.push(unload);
                }
                else{
                    int totalElevatorTime;
                    totalElevatorTime = getLoadTime(peopleGettingOff) + getElevatorTime(currentEvent.floor);
                    Event returnToLobby = {"elevatorReturnToLobby", t + totalElevatorTime, 0, 0, currentEvent.elevator};
                    eventList.push(returnToLobby);
                }
                assert(currentEvent.numberOfPeople != 0);
                numStops++;
            }
            else if(currentEvent.type == "elevatorReturnToLobby") {
                cout << "Elevator " << currentEvent.elevator << " returned to the lobby at " << currentEvent.at << endl;
                //Test to see if any one is left in elevator
                assert(elevatorLoads[currentEvent.elevator - 1].size() == 0);
                assert(currentEvent.numberOfPeople == 0);
                //mark that elevator as available
                int elevatorIndex = currentEvent.elevator - 1;
                elevatorStatus[elevatorIndex] = true;
                numStops++;
            }
            else if(currentEvent.type == "elevatorLoadUp") {
                //log message
                cout << "Elevator " << currentEvent.elevator << " loaded up with " << currentEvent.numberOfPeople << " people at " << currentEvent.at << endl;
                int groupSize = currentEvent.numberOfPeople;

                //see how many people are going to each floor
                int nextFloor = 9999;
                for(int i = 0; i < elevatorLoads[currentEvent.elevator - 1].size(); i++){
                    if(elevatorLoads[currentEvent.elevator - 1][i].desiredFloor < nextFloor){
                        nextFloor = elevatorLoads[currentEvent.elevator - 1][i].desiredFloor;
                    }
                }

                //TODO once sorted take off front until no one left for this floor
                int nextGroup = 0;
                for(int i = 0; i < elevatorLoads[currentEvent.elevator - 1].size(); i++){
                    if(elevatorLoads[currentEvent.elevator - 1][i].desiredFloor == nextFloor){
                        nextGroup++;
                    }
                }
                //schedule next drop off
                int totalElevatorTime;
                totalElevatorTime = getLoadTime(groupSize) + getElevatorTime(nextFloor - currentEvent.floor);
                Event unload = {"elevatorUnloadAtFloor", t + totalElevatorTime, nextGroup, nextFloor, currentEvent.elevator};
                eventList.push(unload);
            }

            //check to see if people in queue can enter elevator
            if(pedestrianQueue.size() > 0) {

                //check to see which elevators are available
                bool available = false;
                vector<int> elevatorNumbers = vector<int>();
                for (int i = 0; i < elevatorStatus.size(); i++) {
                    if (elevatorStatus[i]) {
                        available = true;
                        elevatorNumbers.push_back(i + 1);
                    }
                }

                //if elevators are available load as many as you can
                if(available){

                    int spaceLeft = elevatorNumbers.size() * 10;
                    int elevatorIndex = 0;

                    while(pedestrianQueue.size() > 0 && spaceLeft > 0){
                        if(elevatorStatus[elevatorIndex]){
                            //get first person based on arrival time
                            Person currentPerson = pedestrianQueue.front();
                            pedestrianQueue.pop();

                            //Put person in elevator
                            elevatorLoads[elevatorIndex].push_back(currentPerson);

                            //decrement space left in elevators
                            spaceLeft--;
                        }
                        //increment which elevator is chosen and wrap around
                        elevatorIndex++;
                        if(elevatorIndex == ELEVATORS){
                            elevatorIndex = 0;
                        }
                    }

                    for(int i = 0; i < elevatorLoads.size(); i++){
                        //if elevator is being loaded
                        if(elevatorStatus[i] && elevatorLoads[i].size() != 0){
                            //make this elevator busy
                            elevatorStatus[i] = false;

                            //schedule elevator load up
                            int numberOfPeople = elevatorLoads[i].size();
                            Event loadUp = {"elevatorLoadUp", t, numberOfPeople, 0, i + 1};
                            eventList.push(loadUp);
                        }
                    }

                }
            }
            cout << "Queue size: " << pedestrianQueue.size() << endl;
            
            if(pedestrianQueue.size() > MAXQ){
                MAXQ = pedestrianQueue.size();
            }
        }
}

int main( int argc, char* argv[] ){
	int numFLOORS;
	int ELEVATORS;
	int DAYS;

	//argument number 1 is number of floors
	numFLOORS = stoi(argv[1]);
	//argument number 2 is number of elevators
	ELEVATORS = stoi(argv[2]);
	//argument number 3 is random file
    string filename(argc > 3 ? argv[3] : "/dev/null");
    
    //argument 4 is number of days to run simulation
	DAYS = stoi(argv[4]);

    //max number of people that are waiting on elevator across all days
    int MAXQ = 0;

    vector<int> optimalTimes;
    for(int i = 0; i < numFLOORS; i++){
        optimalTimes.push_back(getElevatorTime(i + 1) + getLoadTime(1) * 2);
    }

    int numStops = 0;

    Welford w;
    RandomFile r(filename);

    //run sim over number of days
    for(int j = 0; j < DAYS; j++) {
        runSim(w, r, numFLOORS, ELEVATORS, MAXQ, numStops, optimalTimes, j + 1);
    }

    double averageStops = (double)numStops / ((double)DAYS * ELEVATORS);

    //OUTPUT Statistics with 5 decimal places worth of precision
    
    cout << "OUTPUT stops " << fixed << setprecision(5) << averageStops << endl;
    cout << "OUTPUT max qsize " << fixed << setprecision(5) << MAXQ << endl;
    cout << "OUTPUT average delay "<< fixed << setprecision(5)  << w.xibar << endl;
    cout << "OUTPUT stddev delay " << fixed << setprecision(5) << w.getStandardDeviation() << endl;

	return 0;
}

