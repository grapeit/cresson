import Foundation

class DataCollector {
  var primarySource: (PrimaryDataProvider & DataProvider)!
  private var secondarySources = [DataProvider]()
  private var calculatedSources = [(DataObserver & DataProvider)]()
  private var observers = [DataObserver]()
  private var currentData = [String: DataRegister]()

  func addSecondarySource(_ source: DataProvider) {
    secondarySources.append(source)
  }

  func removeSecondarySource(_ source: DataProvider) {
    //TODO: remove secondary source
  }

  func addCalculatedSource(_ source: DataObserver & DataProvider) {
    calculatedSources.append(source)
  }

  func removeCalculatedSource(_ source: DataObserver & DataProvider) {
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
}

extension DataCollector: DataProvider {
  var data: [DataRegister] {
    return currentData.map { $0.value }
  }

  func enumRegisterIds(id: (String) -> Void) {
    primarySource.enumRegisterIds(id: id)
    for source in secondarySources {
      source.enumRegisterIds(id: id)
    }
    for source in calculatedSources {
      source.enumRegisterIds(id: id)
    }
  }
}

extension DataCollector: DataObserver {
  func status(_ status: DataProviderStatus) {
    for source in calculatedSources {
      source.status(status)
    }
    for observer in observers {
      observer.status(status)
    }
  }

  func data(_ data: [DataRegister]) {
    currentData.removeAll()
    for register in data {
      currentData[register.id] = register
    }
    for source in secondarySources {
      for register in source.data {
        currentData[register.id] = register
      }
    }
    var registers = currentData.map { $0.value }
    if !calculatedSources.isEmpty {
      for source in calculatedSources {
        source.data(registers)
        for register in source.data {
          currentData[register.id] = register
        }
      }
      registers = currentData.map { $0.value }
    }
    for observer in observers {
      observer.data(registers)
    }
  }
}
