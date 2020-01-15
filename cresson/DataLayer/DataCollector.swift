import Foundation

class DataCollector {
  var primarySource: PrimaryDataProvider!
  private var secondarySources = [SecondaryDataProvider]()
  private var calculatedSources = [CalculatedDataProvider]()
  private var observers = [DataObserver]()
  private var currentData = [String: DataRegister]()

  func addSecondarySource(_ source: SecondaryDataProvider) {
    secondarySources.append(source)
  }

  func removeSecondarySource(_ source: SecondaryDataProvider) {
    //TODO: remove secondary source
  }

  func addCalculatedSource(_ source: CalculatedDataProvider) {
    calculatedSources.append(source)
  }

  func removeCalculatedSource(_ source: CalculatedDataProvider) {
    //TODO: remove calculated source
  }

  func addObserver(_ observer: DataObserver) {
    observers.append(observer)
  }

  func removeObserver(_ observer: DataObserver) {
    //TODO: remove observer
  }

  func getRegister(_ id: String) -> DataRegister? {
    return currentData[id]
  }

  func status(_ status: DataProviderStatus) {
    for observer in observers {
      observer.status(status)
    }
  }

  func data(_ primaryData: [DataRegister]) {
    currentData.removeAll()
    for register in primaryData {
      currentData[register.id] = register
    }
    for source in secondarySources {
      for register in source.getData() {
        currentData[register.id] = register
      }
    }
    for source in calculatedSources {
      for register in source.calculate(currentData) {
        currentData[register.id] = register
      }
    }
    for observer in observers {
      observer.data(currentData)
    }
  }
}
