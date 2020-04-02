//
//  NYPLNetworkResponder.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/22/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

//------------------------------------------------------------------------------
fileprivate struct NYPLNetworkTaskInfo {
  var progressData: Data
  var startDate: Date
  var completion: ((NYPLResult<Data>) -> Void)

  init(completion: (@escaping (NYPLResult<Data>) -> Void)) {
    self.progressData = Data()
    self.startDate = Date()
    self.completion = completion
  }
}

//------------------------------------------------------------------------------
class NYPLNetworkResponder: NSObject, URLSessionDelegate, URLSessionDataDelegate {
  typealias TaskID = Int

  private var taskInfo: [TaskID: NYPLNetworkTaskInfo]

  /// Protects access to `taskInfo`.
  private let taskInfoLock: NSRecursiveLock

  override init() {
    self.taskInfo = [Int: NYPLNetworkTaskInfo]()
    self.taskInfoLock = NSRecursiveLock()
    super.init()
  }

  func addCompletion(_ completion: @escaping (NYPLResult<Data>) -> Void,
                     taskID: TaskID) {
    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    taskInfo[taskID] = NYPLNetworkTaskInfo(completion: completion)
  }

  //----------------------------------------------------------------------------
  // MARK: - URLSessionDelegate

  func urlSession(_ session: URLSession, didBecomeInvalidWithError err: Error?) {
    NYPLErrorLogger.logNetworkError(err, message: "URLSession became invalid")

    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    taskInfo.removeAll()
  }

  //----------------------------------------------------------------------------
  // MARK: - URLSessionDataDelegate

  func urlSession(_ session: URLSession,
                  dataTask: URLSessionDataTask,
                  didReceive data: Data) {
    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    var currentTaskInfo = taskInfo[dataTask.taskIdentifier]
    currentTaskInfo?.progressData.append(data)
    taskInfo[dataTask.taskIdentifier] = currentTaskInfo
  }

  func urlSession(_ session: URLSession,
                  dataTask: URLSessionDataTask,
                  willCacheResponse proposedResponse: CachedURLResponse,
                  completionHandler: @escaping (CachedURLResponse?) -> Void) {

    guard let httpResponse = proposedResponse.response as? HTTPURLResponse else {
      completionHandler(proposedResponse)
      return
    }

    if httpResponse.hasSufficientCachingHeaders {
      completionHandler(proposedResponse)
    } else {
      let newResponse = httpResponse.modifyingCacheHeaders()
      completionHandler(CachedURLResponse(response: newResponse,
                                          data: proposedResponse.data))
    }
  }

  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    let taskID = task.taskIdentifier

    taskInfoLock.lock()

    guard let currentTaskInfo = taskInfo.removeValue(forKey: taskID) else {
      NYPLErrorLogger.logNetworkError(
        requestURL: task.originalRequest?.url,
        response: task.response,
        message: "No task info available for task \(taskID)")
      return
    }

    taskInfoLock.unlock()

    let elapsed = Date().timeIntervalSince(currentTaskInfo.startDate)
    Log.debug(#file, "Task \(taskID) completed, elapsed time: \(elapsed) sec")

    if let error = error {
      NYPLErrorLogger.logNetworkError(
        error,
        requestURL: task.originalRequest?.url,
        response: task.response,
        message: "Task \(taskID) completed with error")
      currentTaskInfo.completion(.failure(error))
      return
    }

    currentTaskInfo.completion(.success(currentTaskInfo.progressData))
  }

}