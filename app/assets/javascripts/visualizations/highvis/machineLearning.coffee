###
  * Copyright (c) 2011, iSENSE Project. All rights reserved.
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * Redistributions of source code must retain the above copyright notice, this
  * list of conditions and the following disclaimer. Redistributions in binary
  * form must reproduce the above copyright notice, this list of conditions and
  * the following disclaimer in the documentation and/or other materials
  * provided with the distribution. Neither the name of the University of
  * Massachusetts Lowell nor the names of its contributors may be used to
  * endorse or promote products derived from this software without specific
  * prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  * ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
  * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
  * DAMAGE.
  *
###
$ ->
  if namespace.controller is 'visualizations' and
  namespace.action in ['displayVis', 'embedVis', 'show']

    class window.MachineLearning extends Scatter
      ###
      Initialize constants for machine learning display mode
      ###
      constructor: (@canvas) ->

        @numClusters = 3
        
        data.dataPointsBackup = []
        data.groupsBackup = []
        data.groupSelectionBackup = []

        super(@canvas)

      start: (animate = true) ->
        super(animate)

      update: ->

        console.log(@canvas)

        newNumClusters = parseInt($('#ml-num-clusters').val())

        unless (isNaN(newNumClusters) or newNumClusters < 1)
          @numClusters = newNumClusters

        #console.log("NumClusters " + @numClusters)

        simplifiedData = []
        #console.log(data)
        #console.log(data.dataPoints.length)

        # simplifiedData = data.dataPoints.map((x) -> x.slice(6, data.dataPoints[0].length))
        for i in [0...data.dataPoints.length]
          simplifiedData[i] = data.dataPoints[i].slice(6, data.dataPoints[i].length)
          #console.log(simplifiedData[i])
          for j in [0...simplifiedData[i].length]
            if typeof simplifiedData[i][j] == 'string'
              # console.log(simplifiedData[i][j])
              # console.log(hashString(simplifiedData[i][j]))
              simplifiedData[i][j] = hashString(simplifiedData[i][j])

        #console.log(simplifiedData)
        clustering = ML.KMeans(simplifiedData, @numClusters, {initialization: simplifiedData.slice(0, @numClusters)})
        #console.log(clustering)

        data.clustering = clustering

        if data.groupsBackup.length == 0
          data.groupsBackup = data.groups
        if data.groupSelectionBackup.length == 0
          data.groupSelectionBackup = data.groupSelection
        if data.dataPointsBackup.length == 0
          data.dataPointsBackup = data.dataPoints

        data.groups = []
        data.groupSelection = []
        for i in [0...@numClusters]
          data.groups.push "Cluster #{i+1}"
          data.groupSelection.push i
        for i in [0...data.dataPoints.length]
          data.dataPoints[i][1] = data.groups[clustering.clusters[i]]

        #console.log(data)

        super()
        #console.log(@chart)

        for i in [0...@chart.series.length]
          @chart.series[i].color = globals.getColor(0)

        #data.groups = data.groupsBackup
        #data.groupSelection = data.groupSelectionBackup
        #data.dataPoints = data.dataPointsBackup


      drawMachineLearningControls: ->
        inctx = {}
        outctx = {}
        outctx.id = 'machinelearning-ctrls'
        outctx.title = 'Machine Learning'
        outctx.body = HandlebarsTemplates[hbCtrl('machinelearning')](inctx)
        machinelearning = HandlebarsTemplates[hbCtrl('body')](outctx)
        $('#vis-ctrls').append(machinelearning)

        globals.configs.machineLearningOpen ?= false
        initCtrlPanel('machinelearning-ctrls', 'machinelearningOpen')

        $('#ml-recluster').click =>
          @update()

      saveFilters: (vis = 'machinelearning') ->
        super(vis)

      kmeansClustering: ->
        #console.log("Welcome to the world of ML")

    if 'Machine Learning' in data.relVis
      globals.machinelearning = new MachineLearning 'machinelearning-canvas'
    else
      globals.machinelearning = new DisabledVis 'machinelearning-canvas'
