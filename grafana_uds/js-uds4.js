var series = context.panel.data.series || [];
var queryA = null;
var queryB = null;
var queryC = null;
var queryD = null;
var queryE = null;
var queryF = null;

for (var i = 0; i < series.length; i++) {
  if (series[i].refId === 'A') queryA = series[i];
  if (series[i].refId === 'B') queryB = series[i];
  if (series[i].refId === 'C') queryC = series[i];
  if (series[i].refId === 'D') queryD = series[i];
  if (series[i].refId === 'E') queryE = series[i];
  if (series[i].refId === 'F') queryF = series[i];
}

var problemsA = [];
var problemsB = [];
var problemsC = [];
var problemsD = [];
var problemsE = [];
var problemsF = [];


if (queryA && queryA.fields && queryA.fields.length > 0) {
  var valsA = queryA.fields[0].values;
  problemsA = valsA.buffer ? valsA.buffer : valsA;
}

if (queryB && queryB.fields && queryB.fields.length > 0) {
  var valsB = queryB.fields[0].values;
  problemsB = valsB.buffer ? valsB.buffer : valsB;
}

if (queryC && queryC.fields && queryC.fields.length > 0) {
  var valsC = queryC.fields[0].values;
  problemsC = valsC.buffer ? valsC.buffer : valsC;
}

if (queryD && queryD.fields && queryD.fields.length > 0) {
  var valsD = queryD.fields[0].values;
  problemsD = valsD.buffer ? valsD.buffer : valsD;
}

if (queryE && queryE.fields && queryE.fields.length > 0) {
  var valsE = queryE.fields[0].values;
  problemsE = valsE.buffer ? valsE.buffer : valsE;
}

if (queryF && queryF.fields && queryF.fields.length > 0) {
  var valsF = queryF.fields[0].values;
  problemsF = valsF.buffer ? valsF.buffer : valsF;
}


var countA = problemsA.length || 0;
var countB = problemsB.length || 0;
var countC = problemsC.length || 0;
var countD = problemsD.length || 0;
var countE = problemsD.length || 0;
var countF = problemsD.length || 0;
var totalCount = countA + countB + countC + countD + countE + countF;

var rootColor = totalCount > 0 ? '#fa5252' : '#51cf66';
var rootGlow = totalCount > 0 ? 'rgba(250, 82, 82, 0.8)' : 'rgba(81, 207, 102, 0.8)';

function getStatusColor(count) {
  if (count === 0) return '#51cf66';
  if (count <= 2) return '#fcc419';
  return '#fa5252';
}

function getNodeSize(count, baseSize) {
  if (count === 0) return baseSize;
  if (count <= 2) return baseSize + 3;
  return baseSize + 6;
}

function formatProblems(problems, count) {
  if (count === 0) {
    return '<span style="color:#51cf66">✓ Нет проблем</span>';
  }
  if (!problems || problems.length === 0) {
    return '<span style="color:#fcc419">⚠ Проблем: ' + count + '</span>';
  }

  var text = '<span style="color:#fa5252;font-weight:bold">✖ Проблем: ' + count + '</span><br/><br/>';
  var limit = Math.min(problems.length, 10);

  for (var j = 0; j < limit; j++) {
    var p = problems[j];
    var name = 'Неизвестная ошибка';

    if (typeof p === 'string') {
      name = p;
    } else if (p && p.trigger) {
      name = p.trigger;
    } else if (p && p.name) {
      name = p.name;
    } else if (p && p.text) {
      name = p.text;
    }

    text += '<span style="color:#adb5bd">' + (j + 1) + '.</span> ' + name + '<br/>';
  }

  if (problems.length > 10) {
    text += '<br/><span style="color:#868e96">... и ещё ' + (problems.length - 10) + '</span>';
  }

  return text;
}

var blinkIndex = 0;

if (totalCount > 0) {
  if (window.__erpBlinkTimer) {
    clearInterval(window.__erpBlinkTimer);
  }

  window.__erpBlinkTimer = setInterval(function () {
    try {
      if (!context.panel || !context.panel.chart) {
        return;
      }

      blinkIndex = (blinkIndex + 1) % 2;
      var opacity = blinkIndex === 0 ? 1 : 0.4;
      var shadowBlur = blinkIndex === 0 ? 30 : 10;

      var currentOption = context.panel.chart.getOption();
      if (currentOption && currentOption.series && currentOption.series[0] && currentOption.series[0].data) {
        var newData = JSON.parse(JSON.stringify(currentOption.series[0].data));
        if (newData[0]) {
          newData[0].itemStyle = newData[0].itemStyle || {};
          newData[0].itemStyle.opacity = opacity;
          newData[0].itemStyle.shadowBlur = shadowBlur;

          context.panel.chart.setOption({
            series: [{
              data: newData
            }]
          }, {
            notMerge: false,
            lazyUpdate: true
          });
        }
      }
    } catch (e) {
      console.log('Blink error:', e);
    }
  }, 800);
} else {
  if (window.__erpBlinkTimer) {
    clearInterval(window.__erpBlinkTimer);
    window.__erpBlinkTimer = null;
  }
}

return {
  tooltip: {
    trigger: 'item',
    triggerOn: 'mousemove',
    confine: true,
    backgroundColor: 'rgba(20, 20, 30, 0.98)',
    borderColor: '#495057',
    borderWidth: 1,
    textStyle: {
      color: '#e9ecef',
      fontSize: 11,
      fontFamily: 'Consolas, Monaco, monospace',
      lineHeight: 16
    },
    padding: [10, 14, 10, 14],
    formatter: function (params) {
      var name = params.name || 'Неизвестный узел';
      var details = params.value || '<span style="color:#868e96">Нет данных</span>';

      if (name.indexOf('MSSQL') !== -1 || name.indexOf('erp') !== -1) {
        details = formatProblems(problemsA, countA);
      } else if (name.indexOf('Сервер 1C') !== -1 || name.indexOf('rphost') !== -1 || name.indexOf('Кластер') !== -1) {
        details = formatProblems(problemsB, countB);
      } else if (name.indexOf('База данных') !== -1 ) {
        details = formatProblems(problemsC, countC);
      }

      return '<div style="min-width:200px">' +
        '<div style="color:#74c0fc; font-weight: bold; margin-bottom: 8px; font-size: 13px; border-bottom: 1px solid #495057; padding-bottom: 6px;">' + name + '</div>' +
        '<div style="line-height: 1.6;">' + details + '</div>' +
        '</div>';
    }
  },
  series: [{
    type: 'tree',
    data: [{
      name: '1C ERP\nПроблем: ' + totalCount,
      symbol: 'roundRect',
      symbolSize: [110, 40],
      itemStyle: {
        color: rootColor,
        borderColor: '#fff',
        borderWidth: 3,
        shadowBlur: totalCount > 0 ? 30 : 15,
        shadowColor: rootGlow,
        opacity: 1
      },
      label: {
        position: 'inside',
        color: '#fff',
        fontSize: 10,
        fontWeight: 'bold',
        lineHeight: 14
      },
      emphasis: {
        itemStyle: {
          shadowBlur: 40,
          borderWidth: 4,
          borderColor: '#ffd43b'
        }
      },
      children: [
        {
          name: 'База данных ERP\nПроблем: ' + countC,
          symbol: 'diamond',
          symbolSize: getNodeSize(countC, 14),
          itemStyle: {
            color: getStatusColor(countC),
            borderColor: '#fff',
            borderWidth: 2,
            shadowBlur: countC > 0 ? 20 : 8,
            shadowColor: getStatusColor(countC)
          },
          label: {
            position: 'left',
            align: 'right',
            distance: 5,
            color: '#e9ecef',
            fontSize: 10
          },
          children: [{
            name: 'ERP',
            symbol: 'circle',
            symbolSize: 14,
            itemStyle: {
              color: '#748ffc',
              borderColor: '#fff',
              borderWidth: 1
            },
            label: {
              position: 'left',
              distance: 25,
              color: '#e9ecef',
              fontSize: 10
            },
            children: [{
              name: 'MSSQLSERVER\nПроблем: ' + countA,
              symbol: 'rect',
              symbolSize: [100, 28],
              itemStyle: {
                color: countA > 0 ? '#fa5252' : '#2b8a3e',
                borderColor: '#fff',
                borderWidth: 1,
                shadowBlur: countA > 0 ? 15 : 5,
                shadowColor: countA > 0 ? '#fa5252' : '#2b8a3e'
              },
              label: {
                position: 'inside',
                color: '#fff',
                fontSize: 9,
                lineHeight: 12
              }
            }]
          }]
        },
        {
          name: 'Сервер 1C',
          symbol: 'diamond',
          symbolSize: getNodeSize(countB, 14),
          itemStyle: {
            color: getStatusColor(countB),
            borderColor: '#fff',
            borderWidth: 2,
            shadowBlur: countB > 0 ? 20 : 8,
            shadowColor: getStatusColor(countB)
          },
          label: {
            position: 'left',
            distance: 30,
            color: '#e9ecef',
            fontSize: 10
          },
          children: [
            {
              name: 'Кластер 1C',
              symbol: 'circle',
              symbolSize: 12,
              itemStyle: {
                color: '#51cf66',
                borderColor: '#fff',
                borderWidth: 2,
                shadowBlur: 10,
                shadowColor: '#51cf66'
              },
              label: {
                position: 'bottom',
                distance: 10,
                color: '#e9ecef',
                fontSize: 10
              }
            },
            {
              name: 'IIS',
              symbol: 'circle',
              symbolSize: 12,
              itemStyle: {
                color: '#51cf66',
                borderColor: '#fff',
                borderWidth: 2,
                shadowBlur: 10,
                shadowColor: '#51cf66'
              },
              label: {
                position: 'bottom',
                distance: 10,
                color: '#e9ecef',
                fontSize: 10
              }
            },
            {
              name: 'Сервер приложений',
              symbol: 'circle',
              symbolSize: 10,
              itemStyle: {
                color: '#748ffc',
                borderColor: '#fff',
                borderWidth: 1
              },
              label: {
                position: 'right',
                distance: 50,
                color: '#e9ecef',
                fontSize: 10
              },
              children: [{
                name: 'rphost\nПроблем: ' + countB,
                symbol: 'rect',
                symbolSize: [100, 28],
                itemStyle: {
                  color: countB > 0 ? '#fa5252' : '#2b8a3e',
                  borderColor: '#fff',
                  borderWidth: 1,
                  shadowBlur: countB > 0 ? 15 : 5,
                  shadowColor: countB > 0 ? '#fa5252' : '#2b8a3e'
                },
                label: {
                  position: 'inside',
                  color: '#fff',
                  fontSize: 9,
                  lineHeight: 12
                }
              }]
            }
          ]
        },
        {
          name: 'Инфраструктура',
          symbol: 'diamond',
          symbolSize: 25,
          itemStyle: {
            color: '#3bc9db',
            borderColor: '#fff',
            borderWidth: 2,
            shadowBlur: 10,
            shadowColor: '#3bc9db'
          },
          label: {
            position: 'left',
            align: 'right',
            distance: 4,
            color: '#e9ecef',
            fontSize: 10
          },
          children: [{
            name: 'SRV-V1',
            symbol: 'circle',
            symbolSize: 10,
            itemStyle: {
              color: '#748ffc',
              borderColor: '#fff',
              borderWidth: 1
            },
            label: {
              position: 'left',
              distance: 10,
              align: 'right',
              verticalAlign: 'middle',
              color: '#e9ecef',
              fontSize: 10
            },
            children: [{
              name: '2Base_ERP',
              symbol: 'circle',
              symbolSize: 10,
              itemStyle: {
                color: '#748ffc',
                borderColor: '#fff',
                borderWidth: 1
              },
              label: {
                position: 'left',
                distance: 10,
                align: 'right',
                verticalAlign: 'middle',
                color: '#e9ecef',
                fontSize: 10
              },
              children: [{
                name: 'vSphere 8',
                symbol: 'circle',
                symbolSize: 10,
                itemStyle: {
                  color: '#748ffc',
                  borderColor: '#fff',
                  borderWidth: 1
                },
                label: {
                  position: 'left',
                  distance: 10,
                  align: 'right',
                  verticalAlign: 'middle',
                  color: '#e9ecef',
                  fontSize: 10
                },
                children: [
                  {
                    name: 'ESXi',
                    symbol: 'pin',
                    symbolSize: 14,
                    itemStyle: {
                      color: '#868e96',
                      borderColor: '#fff',
                      borderWidth: 1
                    },
                    label: {
                      position: 'left',
                      align: 'right',
                      distance: 4,
                      color: '#adb5bd',
                      fontSize: 9
                    }
                  },
                  {
                    name: 'vCenter',
                    symbol: 'pin',
                    symbolSize: 14,
                    itemStyle: {
                      color: '#51cf66',
                      borderColor: '#fff',
                      borderWidth: 2,
                      shadowBlur: 10,
                      shadowColor: '#51cf66'
                    },
                    label: {
                      position: 'right',
                      align: 'left',
                      distance: 4,
                      color: '#adb5bd',
                      fontSize: 9
                    }
                  }
                ]
              }]
            }]
          }]
        }
      ]
    }],
    top: '8%',
    left: '12%',
    bottom: '8%',
    right: '5%',
    symbolSize: 10,
    orient: 'TB',
    layout: 'orthogonal',
    edgeShape: 'curve',
    edgeForkPosition: '50%',
    initialTreeDepth: -1,
    roam: true,
    scaleLimit: { min: 0.3, max: 3 },
    lineStyle: {
      color: '#495057',
      width: 4,
      curveness: 1,
      type: 'solid'
    },
    emphasis: {
      focus: 'ancestor',
      lineStyle: {
        width: 4,
        color: '#74c0fc'
      }
    },
    label: {
      position: 'bottom',
      verticalAlign: 'middle',
      align: 'center',
      fontSize: 10,
      distance: 6,
      color: '#e9ecef'
    },
    expandAndCollapse: true,
    animationDuration: 550,
    animationDurationUpdate: 750
  }]
};
