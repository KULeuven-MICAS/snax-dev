<%def name="list_elem(prop)">\
  % for c in cfg[prop]:
${c}${', ' if not loop.last else ''}\
  % endfor
</%def>\
package streamer

import chisel3._
import chisel3.util._

/** Parameter definitions fifoWidthReader - FIFO width for the data readers
  * fifoDepthReader - FIFO depth for the data readers fifoWidthWriter - FIFO
  * width for the data writers fifoDepthWriter - FIFO depth for the data writers
  * dataReaderNum - number of data readers dataWriterNum - number of data
  * writers dataReaderTcdmPorts - the number of connections to TCDM ports for
  * each data reader dataWriterTcdmPorts - the number of connections to TCDM
  * ports for each data writer readElementWidth - single data element width for
  * each data reader, useful for generating unrolling addresses
  * writeElementWidth - single data element width for each data writer, useful
  * for generating unrolling addresses tcdmDataWidth - data width for each TCDm
  * port unrollingFactorReader - spatial unrolling factors (your parfor) for
  * each data reader unrollingFactorWriter - spatial unrolling factors (your
  * parfor) for each data writer temporalLoopDim - the dimension of the temporal
  * loop temporalLoopBoundWidth - the register width for storing the temporal
  * loop bound addrWidth - the address width stationarity - accelerator
  * stationarity feature for each data mover (data reader and data writer)
  */

// Streamer parameters
object StreamerParameters {
  def fifoWidthReader = Seq(${list_elem('fifoWidthWriter')})
  def fifoDepthReader = Seq(${list_elem('fifoWidthReader')})

  def fifoWidthWriter = ${list_elem('fifoWidthWriter')}
  def fifoDepthWriter = ${list_elem('fifoDepthWriter')}

  def dataReaderNum = ${cfg["dataReaderNum"]}
  def dataWriterNum = ${cfg["dataWriterNum"]}
  def dataReaderTcdmPorts = Seq(${list_elem('dataReaderTcdmPorts')})
  def dataWriterTcdmPorts = Seq(${list_elem('dataWriterTcdmPorts')})
  def readElementWidth = Seq(${list_elem('readElementWidth')})
  def writeElementWidth = Seq(${list_elem('writeElementWidth')})

  def tcdmDataWidth = ${cfg["tcdmDataWidth"]}

  def unrollingFactorReader = Seq(\
% for c in cfg["unrollingFactorReader"]:
Seq(\
  % for d in c:
${d}${', ' if not loop.last else ''}\
  % endfor
)${', ' if not loop.last else ''}\
% endfor
)
  def unrollingFactorWriter = Seq(\
% for c in cfg["unrollingFactorWriter"]:
Seq(\
  % for d in c:
${d}${', ' if not loop.last else ''}\
  % endfor
)${', ' if not loop.last else ''}\
% endfor
)

  def temporalLoopDim = ${cfg["temporalLoopDim"]}
  def temporalLoopBoundWidth = ${cfg["temporalLoopBoundWidth"]}

  def addrWidth = ${cfg["addrWidth"]}

  def stationarity = Seq(${list_elem('stationarity')})

  // inferenced parameters
  def dataMoverNum = dataReaderNum + dataWriterNum
  def tcdmPortsNum = dataReaderTcdmPorts.sum + dataWriterTcdmPorts.sum
  def unrollingDimReader = (0 until unrollingFactorReader.length).map(i =>
    unrollingFactorReader(i).length
  )
  def unrollingDimWriter = (0 until unrollingFactorWriter.length).map(i =>
    unrollingFactorWriter(i).length
  )
  def unrollingDim: Seq[Int] = (0 until unrollingFactorReader.length).map(i =>
    unrollingFactorReader(i).length
  ) ++ (0 until unrollingFactorWriter.length).map(i =>
    unrollingFactorWriter(i).length
  )
}