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

    class window.Histogram extends BaseHighVis
      constructor: (@canvas) ->
        super(@canvas)

      MAX_NUM_BINS:        1000
      binNumSug:              1

      # Wait for global objects to be constructed before getting bin size
      updatedTooltips:    false

      start: ->
        @configs.displayField = Math.min globals.configs.fieldSelection...
        @configs.binSize ?= @defaultBinSize()
        @configs.showNormalCurve = false
        super()

      buildOptions: (animate = true) ->
        super(animate)

        self = this

        @chartOptions
        $.extend true, @chartOptions,
          chart:
            type: 'column'
          legend:
            enabled: false
          title:
            text: ''
          tooltip:
            formatter: ->
              # If total items in a bin = 0, don't show the tooltip
              # This is important for when the normal line is shown
              if @total <= 0
                false
              else
                str  = "<div style='width:100%;text-align:center;'> "
                if @series.name == 'Normal Curve'
                  str += "<b><u>Normal Curve</u></b>"
                  str += "<br>Mean: " + @series.options.mean
                  str += "<br>Standard Deviation: " + @series.options.stddev
                  str += "<br>Skewness: " #+ @series.options.skewness
                  str += "<br>Kurtosis: " #+ @series.options.kurtosis
                  str += "</div>"
                else
                  xField = @series.xAxis.options.title.text
                  idx = data.fields.map((x) -> fieldTitle(x)).indexOf(xField)
                  str += "<b><u>Bin #{@x}</u></b><br>"
                  str += "Contains #{@total} Items<br>"
                  str += "Within the Range #{@x - document.getElementById("bin-size").value / 2}"
                  str += "- #{@x + document.getElementById("bin-size").value / 2}</div><br>"
                  str += "<table>"
                  str += "<tr><td style='text-align: right'>Group :&nbsp;</td>"
                  str += "<td style='color:#{@series.color};'>#{@series.name}</td></tr>"
                  if @y > 0
                    if @y is 1
                      # Print specific value
                      str += "<tr><td style='text-align: right'>#{xField} :&nbsp;</td>"
                      str += "<td style='color:#{@series.color};'>"
                      str += if (@point.realValue == undefined) then "1 in this Bin" else "#{@point.realValue}"
                      str += "</td></tr>"
                    else
                      # Print amount in bin
                      str += "<tr><td style='text-align: right'>Data Points :&nbsp;</td>"
                      str += "<td style='color:#{@series.color};'>#{@y} in this Bin</td></tr>"
                  str += "</table>"
            useHTML: true
          plotOptions:
            column:
              stacking: 'normal'
              groupPadding: 0
              pointPadding: 0
            series:
              events:
                legendItemClick: (event) ->
                  false
          xAxis: [
            {alignTicks: false},
            lineWidth: 0
            categories: ['']
          ]

      ###
      Returns a rough default 'human-like' bin size selection
      ###
      defaultBinSize: ->
        min = Number.MAX_VALUE
        max = Number.MIN_VALUE

        dp = globals.getData(true, globals.configs.activeFilters)

        for groupIndex in data.groupSelection
          localMin = data.getMin(@configs.displayField, groupIndex, dp)
          if localMin?
            min = Math.min(min, localMin)

          localMax = data.getMax(@configs.displayField, groupIndex, dp)
          if localMax?
            max = Math.max(max, localMax)

        range = max - min

        # No data
        if max < min
          return 1

        curSize = 1
        bestSize = curSize
        bestNum  = range / curSize
        binNumTarget = Math.pow(10, @binNumSug)

        tryNewSize = (size) ->
          target = Math.abs(binNumTarget - (range / size))
          if target >= Math.abs(binNumTarget - bestNum)
            return false

          bestSize = size
          bestNum  = range / size
          return true

        loop
          if (range / curSize) < binNumTarget
            curSize /= 10
          else if (range / curSize) > binNumTarget
            curSize *= 10

          break if not tryNewSize(curSize)

        tryNewSize(curSize / 2)
        tryNewSize(curSize * 2)
        tryNewSize(curSize / 5)
        tryNewSize(curSize * 5)
        return bestSize

      update: ->
        super()
        # Name Axis
        @chart.yAxis[0].setTitle({text: "Quantity"}, false)
        @chart.xAxis[0].setTitle(
          {text: fieldTitle(data.fields[@configs.displayField])}, false)
        if data.groupSelection.length is 0 then return

        while @chart.series.length > data.normalFields.length
          @chart.series[@chart.series.length - 1].remove false

        @globalmin = Number.MAX_VALUE
        @globalmax = Number.MIN_VALUE

        dp = globals.getData(true, globals.configs.activeFilters)

        for groupIndex in data.groupSelection
          min = data.getMin(@configs.displayField, groupIndex, dp)
          min = Math.round(min / @configs.binSize) * @configs.binSize
          @globalmin = Math.min(@globalmin, min)

          max = data.getMax(@configs.displayField, groupIndex, dp)
          max = Math.round(max / @configs.binSize) * @configs.binSize
          @globalmax = Math.max(@globalmax, max)

        # Make 'fake' data to ensure proper bar spacing
        fakeDat = for i in [@globalmin...@globalmax] by @configs.binSize
          [i, 0]

        options =
          showInLegend: false
          data: fakeDat

        @chart.addSeries options, false

        # Generate all bin data
        binObjs = {}
        binMesh = {}
        dp = globals.getData(true, globals.configs.activeFilters)
        for groupIndex in data.groupSelection
          selectedData = data.selector(@configs.displayField, groupIndex, dp)

          binArr = for i in selectedData
            x = Math.round(i / @configs.binSize) * @configs.binSize
            unless binMesh[x]?
              binMesh[x] = []
            binMesh[x].push i
            x

          binObjs[groupIndex] = {}

          for bin in binArr
            binObjs[groupIndex][bin] ?= 0
            binObjs[groupIndex][bin]++

        # Convert bin data into series data
        i = 0
        binSizes = {}
        binTotals = {}

        (key for key of binObjs).map((y) -> ({x: Number(val), y: binObjs[y][val]} for val of binObjs[y])).map (a) ->
          a.map (b) ->
            binSizes[b['x']] ?= 0
            binSizes[b['x']] = Math.max(binSizes[b['x']], b['y'])
            binTotals[b['x']] ?= 0
            binTotals[b['x']] += b['y']
        max = (pv, cv, index, array) -> Math.max(pv, cv)
        min = (pv, cv, index, array) -> Math.min(pv, cv)
        largestBin = (binTotals[key] for key of binTotals).reduce max, 0
        smallestBin = (binTotals[key] for key of binTotals).reduce min, 0
        maxValueAnyGroupAnyBin = (binSizes[key] for key of binSizes).reduce max, 0

        if largestBin < 100 and maxValueAnyGroupAnyBin < 50
          for group of binObjs
            maxValueOneGroupAnyBin = \
            (binObjs[group][key] for key of binObjs[group]).reduce max, 0
            while i < maxValueOneGroupAnyBin
              binData = []
              for bin of binObjs[group]
                if binObjs[group][bin] > i
                  x = binMesh[bin].pop()
                  binData.push
                    x: Number(bin)
                    y: 1
                    total: binObjs[group][bin]
                    realValue: x
              binData.sort (a, b) -> Number(a['x']) - Number(b['x'])
              options =
                showInLegend: false
                color: globals.getColor(Number(group))
                name: data.groups[Number(group)]
                data: binData
              @chart.addSeries options, false
              i += 1
            i = 0
        else
          for groupIndex in data.groupSelection
            finalData = for number, occurences of binObjs[groupIndex]
              sum = 0

              # Get total for this bin
              for dc, groupData of binObjs
                if groupData[number]
                  sum += groupData[number]

              ret =
                x: (Number number)
                y: occurences
                total: sum

            options =
              showInLegend: false
              color: globals.getColor(groupIndex)
              name: data.groups[groupIndex]
              data: finalData

            @chart.addSeries options, false

        half = @configs.binSize / 2
        @chart.xAxis[0].setExtremes(@globalmin - half, @globalmax + half, true)

        # Remove old invalid normal curve data/axes
        if @chart.get('normal-curve-data') != null
          @chart.get('normal-curve-data').remove()
        if @chart.get('normal-curve-y-axis') != null
          @chart.get('normal-curve-y-axis').remove()
        if @chart.get('normal-curve-x-axis') != null
          @chart.get('normal-curve-x-axis').remove()

        # Build Normal Curve
        if @configs.showNormalCurve
          dp = globals.getData(true, globals.configs.activeFilters)
          groupSel = data.groupSelection
          mean = data.getMean(@configs.displayField, groupSel, dp)
          stddev = data.getStandardDeviation(@configs.displayField, groupSel, dp)

          # Build list of valid data points
          validData = []
          for d in dp
            validData.push d[@configs.displayField] if d[@configs.displayField]?
          n = validData.length

          # Calculate skewness
          sum1 = sum2 = 0
          for i in [0...n]
            sum1 += Math.pow((validData[i] - mean), 3)
            sum2 += Math.pow((validData[i] - mean), 2)
          skewness = ((1/n)*sum1) / Math.pow(((1/n)*sum2), (3/2))

          # Calculate kurtosis
          sum1 = sum2 = 0

          normalCurveData = []
          numberOfPoints = 100
          xMin =  @chart.xAxis[0].min - (@configs.binSize / 2)
          xMax =  @chart.xAxis[0].max + (@configs.binSize / 2)
          normalCurveInterval = (xMax - xMin) / numberOfPoints

          # Calculate points to plot for the normal curve
          x = xMin
          while x <= xMax
            y = (1/Math.sqrt(2*(Math.pow(stddev, 2)*Math.PI)))
            y *= (Math.pow(Math.E, (-(Math.pow((x-mean), 2))/(2*(Math.pow(stddev, 2))))))
            normalCurveData.push [x, y]
            x += normalCurveInterval

          # Figure out the line color
          lineColor = data.groupSelection[0]
          for e in data.groupSelection
            if e > lineColor
              lineColor = e
          lineColor += 1

          normalCurveYAxisOptions =
            id: 'normal-curve-y-axis'
            opposite: true
            title:
              text: 'Normal Distribution'
            min: 0

          normalCurveXAxisOptions =
            id: 'normal-curve-x-axis'
            lineWidth: 0
            minorGridLineWidth: 0
            lineColor: 'transparent'
            labels:
              enabled: false
            minorTickLength: 0
            tickLength: 0
            linkedTo: 0

          normalCurveSeriesOptions =
            id: 'normal-curve-data'
            showInLegend: false
            color: globals.getColor(lineColor)
            name: 'Normal Curve'
            data: normalCurveData
            type: 'spline'
            yAxis: 'normal-curve-y-axis'
            xAxis: 'normal-curve-x-axis'
            marker:
              enabled: false
              states:
                hover:
                  enabled: false
            lineWidth: 3
            mean: mean
            stddev: stddev
            skewness: skewness
            kurtosis: kurtosis

          @chart.addAxis(normalCurveXAxisOptions, true)
          @chart.addAxis normalCurveYAxisOptions
          @chart.addSeries normalCurveSeriesOptions

          # Need to rerun buildOptions() because the first time it was run, there was not enough info
          # to calculate the mean and standard deviation for the tooltip
          @buildOptions(false)

      buildLegendSeries: ->
        count = -1
        for f, i in data.fields when i in data.normalFields
          count += 1
          dummy =
            data: []
            color: '#000'
            visible: @configs.displayField is i
            name: f.fieldName
            xAxis: 1
            legendIndex: i

      drawToolControls: ->
        inctx =
          binSize: @configs.binSize

        if data.hasTimeData and data.timeType != data.GEO_TIME
          inctx.period = HandlebarsTemplates[hbCtrl('period')]

        inctx.normalCurve =
          id:       'normal-curve'
          logId:    'normal-curve'
          label:    'Normal Curve'

        outctx =
          id: 'tools-ctrls'
          title: 'Tools'
          body: HandlebarsTemplates[hbCtrl('histogram-tools')](inctx)

        tools = HandlebarsTemplates[hbCtrl('body')](outctx)
        $('#vis-ctrls').append(tools)

        # Just to make sure normal curve checkbox is properly checked/unchecked
        document.getElementById('ckbx-normal-curve').checked = @configs.showNormalCurve

        # Set the correct options for period:
        $('#period-list').val(globals.configs.periodMode)

        $('#period-list').change =>
          globals.configs.periodMode = $('#period-list').val()
          if $('#period-list').val() != 'off'
            globals.configs.isPeriod = true
          else
            globals.configs.isPeriod = false
          $( "#group-by" ).trigger( "change" )
          @start()

        # Adds material design
        $('#vis-ctrls').find(".mdl-checkbox").each (i,j) ->
          componentHandler.upgradeElement($(j)[0])

        $('#vis-ctrls').find(".mdl-radio").each (i,j) ->
          componentHandler.upgradeElement($(j)[0])

        # Initialize and track the status of this control panel
        globals.configs.toolsOpen ?= false
        initCtrlPanel('tools-ctrls', 'toolsOpen')

        # Set up slider
        init =
          value: @configs.binSize
          min: .5
          max: 2.2
          step: .1
        $('#bin-size-slider').attr(init)
        $('#bin-size-slider').on 'input change', (e) =>
          @binNumSug = 2.7 - Number(e.target.value)
          newBinSize = @defaultBinSize()
          unless fpEq(newBinSize, @configs.binSize)
            @configs.binSize = newBinSize
            $('#bin-size').val(@configs.binSize)
            @delayedUpdate()

        # Bin Size Box
        badNumberPopoverTimer = null
        $('#set-bin-size-btn').click =>
          $('#bin-size').popover('destroy')
          newBinSize = Number($('#bin-size').val())
          if isNaN(newBinSize) or newBinSize <= 0
            $('#bin-size').popover
              content: 'Please enter a valid number'
              placement: 'bottom'
              trigger: 'manual'
            $('#bin-size').popover('show')
            if badNumberPopoverTimer? then clearTimeout(badNumberPopoverTimer)
            badNumberPopoverTimer = setTimeout ->
              $('#bin-size').popover('destroy')
            , 3000
            return

          if ((@globalmax - @globalmin) / newBinSize) < @MAX_NUM_BINS
            @configs.binSize = newBinSize
            @update()
          else
            alert('Entered bin size would result in too many bins.')

        # Adds Material Design to slider
        $('#vis-ctrls').find(".mdl-slider").each (i,j) ->
          componentHandler.upgradeElement($(j)[0])

        $('#ckbx-normal-curve').click () =>
          @configs.showNormalCurve = not @configs.showNormalCurve
          if @configs.showNormalCurve == false
            @chart.get('normal-curve-data').remove()
            @chart.get('normal-curve-y-axis').remove()
            @chart.get('normal-curve-x-axis').remove()
          @delayedUpdate()

      drawControls: ->
        super()
        # Remove group by number fields, only for pie chart
        groups = $.extend(true, [], data.textFields)
        groups.splice(data.NUMBER_FIELDS_FIELD - 1, 1)
        # Remove Group By Time Period if there is no time data
        if data.hasTimeData is false or data.timeType == data.GEO_TIME
          groups.splice(data.TIME_PERIOD_FIELD - 2, 1)
        @drawGroupControls(groups)

        handler = (selected, selFields) =>
          @yAxisRadioHandler(selected, selFields)
          @configs.binSize = @defaultBinSize()
          $('#bin-size').attr('value', @configs.binSize)

        @drawYAxisControls(globals.configs.fieldSelection,
          data.normalFields.slice(1), true, 'Fields',
          @configs.displayField, handler)
        @drawToolControls()
        @drawClippingControls()
        @drawSaveControls()
        $('[data-toggle="tooltip"]').tooltip();

    if "Histogram" in data.relVis
      globals.histogram = new Histogram 'histogram-canvas'
    else
      globals.histogram = new DisabledVis 'histogram-canvas'
