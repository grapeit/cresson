import React, { Component } from "react";
import "bootstrap/dist/css/bootstrap.css";
import ActiveDays from "./components/activeDays";
import RideChart from "./components/rideChart";

class App extends Component {
  state = { currentDay: null };

  render() {
    return (
      <React.Fragment>
        <ActiveDays onChooseDay={this.onChooseDay} />
        <RideChart day={this.state.currentDay} />
      </React.Fragment>
    );
  }

  onChooseDay = (day) => {
    this.setState({ currentDay: day });
  };
}

export default App;
