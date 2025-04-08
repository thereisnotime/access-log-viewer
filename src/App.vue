<template>
  <v-app :theme="theme">
    <v-app-bar app color="primary" dark>
      <div class="d-flex align-center">
        <v-icon class="mr-2" large>mdi-shield-lock</v-icon>
        <h1>Security Access Log Viewer</h1>
      </div>

      <v-spacer></v-spacer>
      
      <v-btn icon @click="toggleTheme">
        <v-icon>{{ theme === 'dark' ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
      </v-btn>
    </v-app-bar>

    <v-main>
      <v-container>
        <v-row>
          <v-col cols="12">
            <div
              id="dropzone"
              v-bind:class="{ 'drag-hover': dropHovering }"
              @drop.prevent="handleDrop"
              @dragover.prevent="dropHovering = true"
              @dragleave="dropHovering = false"
            >
              Drag one or more access.log files here.

              <br /><br />

              <v-btn @click="$refs.files.click()">Browse Files</v-btn>
              <br class="d-sm-none" />
              or <br class="d-sm-none" />
              <v-btn @click="loadSampleFile">Load sample File</v-btn>
              <input
                @change="handleFileChange"
                type="file"
                multiple
                id="files"
                ref="files"
              />
            </div>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12">
            <v-card>
              <v-list-item v-for="file in files" :key="file.id" two-line>
                <v-list-item-content>
                  <v-list-item-title>{{ file.name }}</v-list-item-title>
                  <v-list-item-subtitle v-if="file.parsed"
                    >Requests:
                    {{ file.parsed.logs.length }}</v-list-item-subtitle
                  >
                  <v-list-item-subtitle v-if="!file.parsed"
                    >Requests: loading... {{ (file.progress * 100).toFixed(0) }}%</v-list-item-subtitle
                  >
                </v-list-item-content>
                <v-list-item-action>
                  <v-btn icon @click="removeFile(file.id)">
                    <icon-trash height="16" width="16" />
                  </v-btn>
                </v-list-item-action>
              </v-list-item>
            </v-card>
          </v-col>
        </v-row>

        <!-- Time Range Filter -->
        <v-row v-if="allLogs && allLogs.length > 0">
          <v-col cols="12">
            <v-card>
              <v-card-title>
                Time Range Filter
                <v-chip v-if="isFiltered" color="accent" small class="ml-2">Active</v-chip>
              </v-card-title>
              <v-card-text>
                <v-row>
                  <v-col cols="12" sm="6" md="5">
                    <v-text-field
                      v-model="startDateFormatted"
                      label="Start Date & Time"
                      prepend-icon="mdi-calendar"
                      readonly
                      @click="startDateMenu = true"
                      @click:clear="startDate = null"
                      clearable
                    ></v-text-field>
                    
                    <v-dialog
                      v-model="startDateMenu"
                      persistent
                      width="auto"
                    >
                      <v-card>
                        <v-card-title>Select Start Date and Time</v-card-title>
                        <v-card-text>
                          <v-row>
                            <v-col cols="12" sm="6">
                              <v-date-picker
                                v-model="startDatePicker"
                                scrollable
                              ></v-date-picker>
                            </v-col>
                            <v-col cols="12" sm="6">
                              <v-time-picker
                                v-model="startTimePicker"
                                format="24hr"
                              ></v-time-picker>
                            </v-col>
                          </v-row>
                        </v-card-text>
                        <v-card-actions>
                          <v-spacer></v-spacer>
                          <v-btn
                            text
                            @click="startDateMenu = false"
                          >
                            Cancel
                          </v-btn>
                          <v-btn
                            color="primary"
                            @click="setStartDate(); startDateMenu = false"
                          >
                            OK
                          </v-btn>
                        </v-card-actions>
                      </v-card>
                    </v-dialog>
                  </v-col>
                  
                  <v-col cols="12" sm="6" md="5">
                    <v-text-field
                      v-model="endDateFormatted"
                      label="End Date & Time"
                      prepend-icon="mdi-calendar"
                      readonly
                      @click="endDateMenu = true"
                      @click:clear="endDate = null"
                      clearable
                    ></v-text-field>
                    
                    <v-dialog
                      v-model="endDateMenu"
                      persistent
                      width="auto"
                    >
                      <v-card>
                        <v-card-title>Select End Date and Time</v-card-title>
                        <v-card-text>
                          <v-row>
                            <v-col cols="12" sm="6">
                              <v-date-picker
                                v-model="endDatePicker"
                                scrollable
                              ></v-date-picker>
                            </v-col>
                            <v-col cols="12" sm="6">
                              <v-time-picker
                                v-model="endTimePicker"
                                format="24hr"
                              ></v-time-picker>
                            </v-col>
                          </v-row>
                        </v-card-text>
                        <v-card-actions>
                          <v-spacer></v-spacer>
                          <v-btn
                            text
                            @click="endDateMenu = false"
                          >
                            Cancel
                          </v-btn>
                          <v-btn
                            color="primary"
                            @click="setEndDate(); endDateMenu = false"
                          >
                            OK
                          </v-btn>
                        </v-card-actions>
                      </v-card>
                    </v-dialog>
                  </v-col>
                  
                  <v-col cols="12" md="2" class="d-flex align-center">
                    <v-btn color="accent" @click="applyTimeFilter">Apply Filter</v-btn>
                    <v-btn text class="ml-2" @click="resetTimeFilter">Reset</v-btn>
                  </v-col>
                </v-row>
                <v-row>
                  <v-col cols="12">
                    <div class="d-flex flex-wrap">
                      <span class="mr-2 mt-2">Presets:</span>
                      <v-btn small :outlined="activePreset === 'today'" class="mr-2 mt-2" :color="activePreset === 'today' ? 'accent' : ''" @click="applyPresetRange('today')">Today</v-btn>
                      <v-btn small :outlined="activePreset === 'yesterday'" class="mr-2 mt-2" :color="activePreset === 'yesterday' ? 'accent' : ''" @click="applyPresetRange('yesterday')">Yesterday</v-btn>
                      <v-btn small :outlined="activePreset === 'last7days'" class="mr-2 mt-2" :color="activePreset === 'last7days' ? 'accent' : ''" @click="applyPresetRange('last7days')">Last 7 Days</v-btn>
                      <v-btn small :outlined="activePreset === 'last30days'" class="mr-2 mt-2" :color="activePreset === 'last30days' ? 'accent' : ''" @click="applyPresetRange('last30days')">Last 30 Days</v-btn>
                      <v-btn small :outlined="activePreset === 'thisMonth'" class="mr-2 mt-2" :color="activePreset === 'thisMonth' ? 'accent' : ''" @click="applyPresetRange('thisMonth')">This Month</v-btn>
                      <v-btn small :outlined="activePreset === 'lastMonth'" class="mr-2 mt-2" :color="activePreset === 'lastMonth' ? 'accent' : ''" @click="applyPresetRange('lastMonth')">Last Month</v-btn>
                    </div>
                  </v-col>
                </v-row>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <v-row v-if="allLogs && allLogs.length > 0">
          <v-col cols="12">
            <v-alert
              v-if="isFiltered && logs.length > 0"
              type="info"
              dense
              outlined
              color="accent"
            >
              Showing filtered data from {{ startDateFormatted || 'earliest record' }} to {{ endDateFormatted || 'latest record' }}. 
              <v-btn small color="accent" @click="resetTimeFilter" class="ml-2">Reset Filter</v-btn>
            </v-alert>
            <v-alert
              v-if="isFiltered && logs.length === 0"
              type="warning"
              dense
              outlined
            >
              No data found in the selected time range. Please adjust your filter or 
              <v-btn small color="accent" @click="resetTimeFilter" class="ml-2">Reset Filter</v-btn>
            </v-alert>
            <v-alert
              v-if="!isFiltered && allLogs && allLogs.length > 0"
              type="success"
              dense
              outlined
              color="secondary"
              class="mt-2"
            >
              Showing all {{ allLogs.length }} log entries.
            </v-alert>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" lg="6">
            <v-card height="100%">
              <v-tabs
                v-model="tab"
                background-color="transparent"
                id="tabs"
              >
                <v-tabs-slider color="accent"></v-tabs-slider>
                <v-tab class="text-capitalize">
                  <div>Sessions</div>
                  <div class="text-h6">{{ numberOfSessions }}</div>
                </v-tab>
                <v-tab class="text-capitalize">
                  <div>Requests</div>
                  <div class="text-h6">{{ numberOfRequests }}</div>
                </v-tab>
                <v-tab class="text-capitalize">
                  <div>Transfer</div>
                  <div class="text-h6">{{ transfer }}</div>
                </v-tab>
              </v-tabs>
              <v-tabs-items v-model="tab">
                <v-tab-item :transition="false">
                  <v-card flat v-if="tab === 0">
                    <v-card-text v-if="logs.length > 0">
                      <GChart
                        type="LineChart"
                        :data="chartDataSessions"
                        :options="{
                          legend: 'none',
                          chartArea: { width: '90%', height: '80%' },
                          colors: $vuetify.theme.dark ? ['#a71d31'] : ['#8B0000'],
                          backgroundColor: 'transparent',
                          pointSize: 6,
                          pointShape: 'circle',
                          lineWidth: 3,
                          curveType: 'function',
                          interpolateNulls: true,
                          tooltip: { isHtml: true },
                          explorer: {
                            actions: ['dragToZoom', 'rightClickToReset'],
                            axis: 'horizontal',
                            keepInBounds: true,
                            maxZoomIn: 0.1
                          },
                          hAxis: {
                              gridlines: {
                                  color: $vuetify.theme.dark ? '#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ? '#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              format: 'MM/dd/yy HH:mm'
                          },
                          vAxis: {
                             gridlines: {
                                  color: $vuetify.theme.dark ?'#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ?'#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              minValue: 0
                          },
                        }"
                      />
                    </v-card-text>
                    <v-card-text v-else class="text-center pa-5">
                      <v-icon large color="grey">mdi-chart-line</v-icon>
                      <div class="grey--text mt-2">No session data available for the selected time range</div>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
                <v-tab-item :transition="false">
                  <v-card flat v-if="tab === 1">
                    <v-card-text v-if="logs.length > 0">
                      <GChart
                        type="LineChart"
                        :data="chartDataRequests"
                        :options="{
                          legend: 'none',
                          chartArea: { width: '90%', height: '80%' },
                          colors: $vuetify.theme.dark ? ['#a71d31'] : ['#8B0000'],
                          backgroundColor: 'transparent',
                          pointSize: 6,
                          pointShape: 'circle',
                          lineWidth: 3,
                          curveType: 'function',
                          interpolateNulls: true,
                          tooltip: { isHtml: true },
                          explorer: {
                            actions: ['dragToZoom', 'rightClickToReset'],
                            axis: 'horizontal',
                            keepInBounds: true,
                            maxZoomIn: 0.1
                          },
                          hAxis: {
                              gridlines: {
                                  color: $vuetify.theme.dark ? '#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ? '#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              format: 'MM/dd/yy HH:mm'
                          },
                          vAxis: {
                             gridlines: {
                                  color: $vuetify.theme.dark ?'#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ?'#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              minValue: 0
                          }
                        }"
                      />
                    </v-card-text>
                    <v-card-text v-else class="text-center pa-5">
                      <v-icon large color="grey">mdi-chart-timeline</v-icon>
                      <div class="grey--text mt-2">No request data available for the selected time range</div>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
                <v-tab-item :transition="false">
                  <v-card flat v-if="tab === 2">
                    <v-card-text v-if="logs.length > 0">
                      <GChart
                        type="LineChart"
                        :data="chartDataTransfer"
                        :options="{
                          legend: 'none',
                          chartArea: { width: '90%', height: '80%' },
                          colors: $vuetify.theme.dark ? ['#a71d31'] : ['#8B0000'],
                          backgroundColor: 'transparent',
                          pointSize: 6,
                          pointShape: 'circle',
                          lineWidth: 3,
                          curveType: 'function',
                          interpolateNulls: true,
                          tooltip: { isHtml: true },
                          explorer: {
                            actions: ['dragToZoom', 'rightClickToReset'],
                            axis: 'horizontal',
                            keepInBounds: true,
                            maxZoomIn: 0.1
                          },
                          hAxis: {
                              gridlines: {
                                  color: $vuetify.theme.dark ? '#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ? '#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              format: 'MM/dd/yy HH:mm'
                          },
                          vAxis: {
                             gridlines: {
                                  color: $vuetify.theme.dark ?'#444' : '#ccc'
                              },
                              minorGridlines: {
                                color: $vuetify.theme.dark ?'#444' : '#ddd'
                              },
                              baselineColor: $vuetify.theme.dark ?'#444' : '#ccc',
                              textStyle: {
                                color: $vuetify.theme.dark ? '#aaa' : '#444'
                              },
                              minValue: 0
                          }
                        }"
                      />
                    </v-card-text>
                    <v-card-text v-else class="text-center pa-5">
                      <v-icon large color="grey">mdi-swap-vertical</v-icon>
                      <div class="grey--text mt-2">No transfer data available for the selected time range</div>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
              </v-tabs-items>
            </v-card>
          </v-col>

          <v-col cols="12" lg="6">
            <v-card height="100%">
              <v-card-title>Countries</v-card-title>
              <v-card-text>
                <GChart
                  type="GeoChart"
                  class="google-geo-chart"
                  :settings="{ packages: ['geochart'] }"
                  :data="chartDataMap"
                  :options="{
                    legend: 'none',
                    datalessRegionColor: $vuetify.theme.dark ? '#333' : '#f5f5f5',
                    colorAxis: { colors: $vuetify.theme.dark ? ['#8f3a3a', '#a71d31'] : ['#ffcdd2', '#8B0000'] },
                    backgroundColor: 'transparent'
                  }"
                />
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" lg="6">
            <v-card height="100%">
              <v-card-title>Top IP Addresses</v-card-title>
              <v-card-text>
                <v-simple-table>
                  <template v-slot:default>
                    <thead>
                      <tr>
                        <th class="text-left">IP Address</th>
                        <th class="text-left">Country</th>
                        <th class="text-left">Network</th>
                        <th class="text-left">Browser</th>
                        <th class="text-right">Requests</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(item, i) in mostIPs" :key="i">
                        <td class="text-left">
                          <ip-address :ip="item.ip || '-'" />
                        </td>
                        <td class="text-left">
                          <img
                            v-if="item.country && item.country.length === 2"
                            width="16" 
                            height="16"
                            :src="`https://flagcdn.com/16x12/${item.country.toLowerCase()}.png`"
                            :alt="item.country"
                            class="mr-1"
                          />
                          {{ item.country || 'Unknown' }}
                        </td>
                        <td class="text-left">{{ item.network || 'Unknown' }}</td>
                        <td class="text-left">
                          <img
                            v-if="item.browser && browserLogos[item.browser]"
                            :src="browserLogos[item.browser]"
                            :alt="item.browser"
                            width="16"
                            height="16"
                            class="mr-1"
                          />
                          {{ item.browser || 'Unknown' }}
                        </td>
                        <td class="text-right">{{ item.hits || 0 }}</td>
                      </tr>
                    </tbody>
                  </template>
                </v-simple-table>
              </v-card-text>
            </v-card>
          </v-col>

          <v-col cols="12" lg="6">
            <v-card height="100%">
              <v-card-title>Browsers</v-card-title>
              <v-card-text>
                <v-simple-table>
                  <template v-slot:default>
                    <thead>
                      <tr>
                        <th class="text-left">Browser</th>
                        <th class="text-right">Sessions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(item, i) in mostBrowsers" :key="i">
                        <td>
                          <img
                            v-if="item.browser && browserLogos[item.browser]"
                            :src="browserLogos[item.browser]"
                            :alt="item.browser"
                            width="16"
                            height="16"
                            class="mr-1"
                          />
                          {{ item.browser || 'Unknown' }}
                        </td>
                        <td class="text-right">{{ item.hits || 0 }}</td>
                      </tr>
                    </tbody>
                  </template>
                </v-simple-table>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" lg="3">
            <v-card height="100%">
              <v-card-title> Sessions by Device </v-card-title>
              <v-card-text
                style="
                  flex-grow: 1;
                  display: flex;
                  flex-direction: column;
                  justify-content: space-around;
                "
              >
                <div style="display: flex; justify-content: center; width: 100%">
                  <div style="width: 120px; text-align: center">
                    <icon-desktop
                      height="32"
                      width="32"
                      style="color: #aaa"
                    /><br />
                    Desktop
                  </div>
                  <div class="text-h5" style="width: 120px; text-align: center">
                    {{ devices.desktop.percentage.toFixed(1) }} %
                  </div>
                </div>
                <div style="display: flex; justify-content: center; width: 100%">
                  <div style="width: 120px; text-align: center">
                    <icon-mobile
                      height="32"
                      width="32"
                      style="color: #aaa"
                    /><br />
                    Mobile
                  </div>
                  <div class="text-h5" style="width: 120px; text-align: center">
                    {{ devices.mobile.percentage.toFixed(1) }} %
                  </div>
                </div>
                <div style="display: flex; justify-content: center; width: 100%">
                  <div style="width: 120px; text-align: center">
                    <icon-tablet
                      height="32"
                      width="32"
                      style="color: #aaa"
                    /><br />
                    Tablet
                  </div>
                  <div class="text-h5" style="width: 120px; text-align: center">
                    {{ devices.tablet.percentage.toFixed(1) }} %
                  </div>
                </div>
              </v-card-text>
            </v-card>
          </v-col>

          <v-col cols="12" lg="4">
            <v-card height="100%">
              <v-card-title>
                <div style="display: flex; width: 100%">
                  <div>Most Requested Files</div>
                  <v-switch
                    style="margin-left: auto; margin-top: 0"
                    v-model="assetSwitch"
                    label="Show Assets"
                  ></v-switch>
                </div>
              </v-card-title>
              <v-card-text>
                <v-simple-table dense>
                  <template v-slot:default>
                    <thead>
                      <tr>
                        <th class="text-left">Page</th>
                        <th class="text-left">Hits</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        v-for="item in assetSwitch
                          ? mostUrls
                          : mostUrlsWithoutAssets"
                        :key="item.url"
                      >
                        <td>
                          <span :title="item.url || ''">{{
                            (item.url || '/').substring(0, 50) +
                            ((item.url && item.url.length > 50) ? "..." : "")
                          }}</span>
                        </td>
                        <td>{{ item.hits || 0 }}</td>
                      </tr>
                    </tbody>
                  </template>
                </v-simple-table>
              </v-card-text>
            </v-card>
          </v-col>

          <v-col cols="12" lg="2">
            <v-card height="100%">
              <v-card-title> Status Codes </v-card-title>
              <v-card-text>
                <v-simple-table dense>
                  <template v-slot:default>
                    <thead>
                      <tr>
                        <th class="text-left">Status</th>
                        <th class="text-left">Hits</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        v-for="item in mostStatusCodes"
                        :key="item.statusCode"
                      >
                        <td>{{ item.statusCode }}</td>
                        <td>{{ item.hits }}</td>
                      </tr>
                    </tbody>
                  </template>
                </v-simple-table>
              </v-card-text>
            </v-card>
          </v-col>

          <v-col cols="12" lg="3">
            <v-card height="100%">
              <v-card-title> Top Referrer </v-card-title>
              <v-card-text>
                <v-simple-table dense>
                  <template v-slot:default>
                    <thead>
                      <tr>
                        <th class="text-left">Referrer</th>
                        <th class="text-left">Hits</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="item in mostReferrers" :key="item.referrer">
                        <td>
                          <span
                            style="
                              display: inline-block;
                              height: 16px;
                              width: 16px;
                              vertical-align: text-bottom;
                            "
                          >
                            <img
                              :src="'https://' + item.referrer + '/favicon.ico'"
                              height="16"
                              width="16"
                              onerror="this.style.display='none'"
                            />
                          </span>
                          {{ item.referrer }}
                        </td>
                        <td>{{ item.hits }}</td>
                      </tr>
                    </tbody>
                  </template>
                </v-simple-table>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12">
            <v-card>
              <v-card-title> Logs </v-card-title>
              <v-card-text v-if="logs.length > 0">
                <v-text-field
                  v-model="search"
                  label="Search"
                  single-line
                  hide-details
                ></v-text-field>

                <v-data-table
                  dense
                  :headers="headers"
                  :items="logs"
                  :search="search"
                  :footer-props="{
                    'items-per-page-options': [10, 20, 30],
                  }"
                  @click:row="showLogDetails"
                >
                  <template v-slot:item.ipAddress="{ item }">
                    <ip-address :ip="item.ipAddress" />
                  </template>
                  <template v-slot:item.transfer="{ item }">
                    {{ prettyBytes(item.transfer) }}
                  </template>
                  <template v-slot:item.url="{ item }">
                    <span :title="item.url">{{
                      item.url.substring(0, 50) +
                      (item.url.length > 50 ? "..." : "")
                    }}</span>
                  </template>
                  <template v-slot:item.date="{ item }">
                    {{
                      item.date.toLocaleDateString() +
                      "&nbsp;" +
                      item.date.toLocaleTimeString()
                    }}
                  </template>
                </v-data-table>
              </v-card-text>
              <v-card-text v-else class="text-center pa-5">
                <v-icon large color="grey">mdi-table-off</v-icon>
                <div class="grey--text mt-2">No log entries found for the selected time range</div>
                <v-btn small color="secondary" @click="resetTimeFilter" class="mt-4">Reset Filter</v-btn>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
    <v-footer padless dark>
      <v-card flat tile width="100%" class="primary lighten-1 text-center">
        <v-card-text>
          <v-btn class="mx-4" icon>
            <a href="https://github.com/rolandstarke/access-log-viewer"
              ><img
                src="images/GitHub-Mark-Light-32px.png"
                height="32"
                width="32"
            /></a>
          </v-btn>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-text>
          This product includes GeoLite2 data created by MaxMind, available from
          <a target="_blank" href="https://www.maxmind.com" style="color: rgba(255, 255, 255, 0.7)"
            >https://www.maxmind.com</a
          >.
        </v-card-text>
      </v-card>
    </v-footer>

    <!-- Log Details Dialog -->
    <v-dialog v-model="logDetailsDialog" max-width="800">
      <v-card>
        <v-card-title class="headline primary white--text">
          Log Details
          <v-spacer></v-spacer>
          <v-btn icon @click="logDetailsDialog = false">
            <v-icon color="white">mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text class="pt-4">
          <v-simple-table dense>
            <template v-slot:default>
              <tbody>
                <tr v-for="(value, key) in filteredLogDetails" :key="key">
                  <th class="text-no-wrap" style="min-width: 120px">
                    {{ formatFieldName(key) }}
                  </th>
                  <td>
                    <span v-if="key === 'date'">{{ formatDateTime(value) }}</span>
                    <span v-else-if="key === 'transfer'">{{ prettyBytes(value) }}</span>
                    <span v-else-if="key === 'url'" class="text-break">{{ value }}</span>
                    <span v-else-if="key === 'statusCode'" :class="getStatusCodeClass(value)">{{ value }}</span>
                    <ip-address v-else-if="key === 'ipAddress'" :ip="value"></ip-address>
                    <span v-else-if="key === 'country' && value && value.length === 2">
                      <img 
                        width="16" 
                        height="12"
                        :src="`https://flagcdn.com/16x12/${value.toLowerCase()}.png`"
                        :alt="value"
                        class="mr-1"
                      />
                      {{ value }}
                    </span>
                    <span v-else-if="key === 'browser' && browserLogos[value]">
                      <img
                        :src="browserLogos[value]"
                        :alt="value"
                        width="16"
                        height="16"
                        class="mr-1"
                      />
                      {{ value }}
                    </span>
                    <span v-else>{{ value }}</span>
                  </td>
                </tr>
              </tbody>
            </template>
          </v-simple-table>
          
          <div class="mt-4" v-if="selectedLogDetails && selectedLogDetails.raw">
            <v-divider class="mb-3"></v-divider>
            <div class="subtitle-1 mb-2 accent--text">Raw Log Entry:</div>
            <v-card outlined class="pa-2 grey lighten-4 black--text" :class="{'grey darken-3 white--text': $vuetify.theme.dark}">
              <pre style="white-space: pre-wrap; word-break: break-all;">{{ selectedLogDetails.raw }}</pre>
            </v-card>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<style>
@import url("https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700,900");
@import url("https://cdn.jsdelivr.net/npm/@mdi/font@4.x/css/materialdesignicons.min.css");

html { overflow-y: auto; }

.v-btn:hover::before {
  opacity: 0.08;
}

#dropzone {
  border: 2px dotted #aaa;
  padding: 20px;
  text-align: center;
}

#dropzone.drag-hover {
  border-color: #4caf50;
  background-color: #eee;
}

#files {
  display: none;
}

#tabs .v-tabs-bar {
  height: 70px !important;
}
#tabs .v-tab {
  flex-direction: column;
}
.theme--dark.v-tabs > .v-tabs-bar .v-tab.v-tab--active {
  color: #fff;
}
.theme--dark .google-geo-chart path[fill*="#_ABSTRACT_RENDERER_ID"] {
  display: none; /* white dots in dark mode visible, no clue what this renders anyway */
}
.theme--dark .google-geo-chart path:hover {
  stroke:#77a8da;
}
.theme--dark .google-visualization-tooltip path {        
  fill: #111;
  stroke: #000;
}
.theme--dark .google-visualization-tooltip text {        
  fill: #eee;
}

/* Make log table rows look clickable */
.v-data-table tbody tr {
  cursor: pointer;
  transition: background-color 0.2s;
}

.v-data-table tbody tr:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.theme--dark .v-data-table tbody tr:hover {
  background-color: rgba(255, 255, 255, 0.05);
}

/* Status code colors */
.success {
  color: #4caf50;
  font-weight: 500;
}

.warning {
  color: #fb8c00;
  font-weight: 500;
}

.error {
  color: #f44336;
  font-weight: 500;
}

/* Make raw log entry more readable */
pre {
  margin: 0;
  font-family: 'Roboto Mono', monospace;
  font-size: 13px;
  line-height: 1.5;
}

/* Theme transition */
.v-application {
  transition: background-color 0.3s ease;
}

/* Dark theme enhancements */
.theme--dark .v-card {
  background-color: #1e1e1e;
  border-color: #333;
}

.theme--dark .v-data-table {
  background-color: #1e1e1e;
}

.theme--dark .v-data-table th {
  color: rgba(255, 255, 255, 0.8);
}

/* Accent color hover effects */
.accent {
  transition: all 0.3s ease;
}

.accent:hover {
  filter: brightness(1.2);
}

/* Night mode toggle button effect */
.v-btn--icon {
  transition: transform 0.3s ease;
}

.v-btn--icon:hover {
  transform: rotate(30deg);
}
</style>
<script>
import Worker from "worker-loader!./worker.js";
import IconTrash from "./components/icons/IconTrash.vue";
import IconDesktop from "./components/icons/IconDesktop.vue";
import IconMobile from "./components/icons/IconMobile.vue";
import IconTablet from "./components/icons/IconTablet.vue";
import IpAddress from "./components/IpAddress.vue";
import { GChart } from "vue-google-charts";
const prettyBytes = require("pretty-bytes");

export default {
  components: {
    IconTrash,
    IconDesktop,
    IconMobile,
    IconTablet,
    IpAddress,
    GChart,
  },
  created() {
    // Initialize theme
    this.$vuetify.theme.dark = this.theme === 'dark';
  },
  data: () => ({
    files: [],
    dropHovering: false,
    tab: 0,
    search: "",
    logs: [],
    allLogs: [], // Store all logs before filtering
    allSessions: [], // Store all sessions before filtering
    startDate: null,
    endDate: null,
    startDateFormatted: '',
    endDateFormatted: '',
    activePreset: '',
    numberOfRequests: 0,
    numberOfSessions: 0,
    transfer: "0 B",
    assetSwitch: 0,
    browserLogos: {
      Firefox: require("./assets/browser-logos/firefox_16x16.png"),
      IE: require("./assets/browser-logos/internet-explorer_9-11_16x16.png"),
      Edge: require("./assets/browser-logos/edge_16x16.png"),
      Chrome: require("./assets/browser-logos/chrome_16x16.png"),
      Safari: require("./assets/browser-logos/safari-ios_16x16.png"),
      Opera: require("./assets/browser-logos/opera_16x16.png"),
      "Samsung Browser": require("./assets/browser-logos/samsung-internet_16x16.png"),
      QQBrowser: require("./assets/browser-logos/qq_16x16.png"),
    },
    devices: {
      desktop: { percentage: 0 },
      tablet: { percentage: 0 },
      mobile: { percentage: 0 },
    },
    mostIPs: [
      { ip: "192.168.1.1", hits: 0, country: "US", browser: "Chrome", network: "Private Network" },
    ],
    mostStatusCodes: [
      { statusCode: 200, hits: 0 },
      { statusCode: 404, hits: 0 },
      { statusCode: 500, hits: 0 },
    ],
    mostReferrers: [
      { referrer: "google.com", hits: 0 },
      { referrer: "bing.com", hits: 0 },
      { referrer: "facebook.com", hits: 0 },
    ],
    mostBrowsers: [
      { browser: "Chrome", hits: 0 },
      { browser: "Firefox", hits: 0 },
      { browser: "Safari", hits: 0 },
      { browser: "Edge", hits: 0 },
    ],
    mostUrls: [
      { url: "/", hits: 0 },
      { url: "/about", hits: 0 },
      { url: "/contact", hits: 0 },
    ],
    firstParse: null,
    mostUrlsWithoutAssets: [{ url: "/", hits: 0 }],
    headers: [
      { text: "Date", value: "date", filterable: false },
      { text: "IP Address", value: "ipAddress" },
      { text: "Method", value: "method" },
      { text: "Page", value: "url" },
      { text: "Status", value: "statusCode" },
      { text: "Transfer", value: "transfer", filterable: false },
    ],
    chartDataSessions: [["Time", "Sessions"], ["2022", 0]],
    chartDataRequests: [["Time", "Requests"], ["2022", 0]],
    chartDataTransfer: [["Time", "Bytes"], ["2022", { v: 0, f: "0 B" }]],
    chartDataMap: [["Country", "Sessions"], ["US", 0]],
    startDateMenu: false,
    startDatePicker: null,
    startTimePicker: null,
    endDateMenu: false,
    endDatePicker: null,
    endTimePicker: null,
    isFiltered: false,
    logDetailsDialog: false,
    selectedLogDetails: null,
    theme: localStorage.getItem('theme') || (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'),
  }),
  computed: {
    filteredLogDetails() {
      if (!this.selectedLogDetails) return {};
      
      // Create a filtered copy without the 'raw' property
      const filtered = {};
      Object.keys(this.selectedLogDetails).forEach(key => {
        if (key !== 'raw') {
          filtered[key] = this.selectedLogDetails[key];
        }
      });
      
      return filtered;
    }
  },
  methods: {
    prettyBytes: prettyBytes,
    getNetworkInfo: function(ip) {
      // Handle special cases
      if (!ip || ip === '-') return 'Unknown';
      
      // Check for private IP ranges
      if (ip.startsWith('10.') || 
          ip.startsWith('172.16.') || 
          ip.startsWith('172.17.') || 
          ip.startsWith('172.18.') || 
          ip.startsWith('172.19.') || 
          ip.startsWith('172.2') || 
          ip.startsWith('172.30.') || 
          ip.startsWith('172.31.') || 
          ip.startsWith('192.168.')) {
        return 'Private Network';
      }
      
      // Check for localhost
      if (ip === '127.0.0.1' || ip === '::1') {
        return 'Localhost';
      }
      
      // For IPv6 addresses
      if (ip.includes(':')) {
        if (ip.startsWith('fc00:') || ip.startsWith('fd00:')) {
          return 'Private IPv6';
        }
        if (ip.startsWith('2001:')) {
          return 'Global IPv6';
        }
        if (ip.startsWith('fe80:')) {
          return 'Link-local IPv6';
        }
      }
      
      // For common ISPs and datacenters based on IP ranges
      if (ip.startsWith('8.8.') || ip.startsWith('8.8.4.') || ip.startsWith('8.8.8.')) {
        return 'Google DNS';
      }
      if (ip.startsWith('13.32.') || ip.startsWith('13.33.') || ip.startsWith('13.35.') || 
          ip.startsWith('52.84.') || ip.startsWith('54.192.')) {
        return 'Amazon AWS';
      }
      if (ip.startsWith('104.16.') || ip.startsWith('104.17.') || ip.startsWith('104.18.')) {
        return 'Cloudflare';
      }
      if (ip.startsWith('216.58.') || ip.startsWith('172.217.') || ip.startsWith('74.125.')) {
        return 'Google';
      }
      if (ip.startsWith('157.240.') || ip.startsWith('31.13.')) {
        return 'Facebook';
      }
      if (ip.startsWith('199.232.') || ip.startsWith('151.101.')) {
        return 'Fastly';
      }
      
      // Default fallback
      return 'Internet';
    },
    parseLog: async function (log, file) {
      function fakeProgress(progress, time) {
        setTimeout(function() {
          if (file.progress < progress) {
            file.progress = progress;
          }
        }, time);
      }
      fakeProgress(0.01, 2000);
      fakeProgress(0.02, 7000);
      fakeProgress(0.03, 15000);
      fakeProgress(0.04, 30000);

      await this.firstParse; //wait for first parse to finish so that worker and geoipdb is in cache

      const parsed = new Promise((resolve) => {
        const worker = new Worker();
        worker.onmessage = function (e) {
          if (e.data.progress !== undefined) {
            if (file && e.data.progress > file.progress) {
              file.progress = e.data.progress;
            }
            return;
          }

          resolve(e.data);
          worker.terminate();
        };
        worker.postMessage(log);
      });

      if (!this.firstParse) {
        const timeout = new Promise(function(resolve){
          setTimeout(resolve, 10000);
        });
        this.firstParse = Promise.race([parsed.catch(() => {}), timeout]);
      }

      
      const timer = "parse " + file.name;
      console.time(timer);
      parsed.then(() => {
        console.timeEnd(timer);
      });

      return parsed;
    },
    removeFile: function (id) {
      this.files = this.files.filter((f) => f.id !== id);
      this.calculateValues();
    },
    handleFileChange: function (e) {
      this.handleFiles(e.target.files);
    },
    handleDrop: function (e) {
      this.dropHovering = false;
      this.handleFiles(e.dataTransfer.files);
    },
    handleFiles: async function (files) {
      const promises = [];
      for (let i = 0; i < files.length; i++) {
        const file = {
          id: Math.random(),
          name: files[i].name,
          parsed: null,
          progress: 0,
        };
        this.files.push(file);
        const promise = Promise.resolve(files[i])
          .then((l) => this.parseLog(l, file))
          .then((parsed) => {
            file.parsed = Object.freeze(parsed); //for perfomrance reasons, so vue does not observe it
          });
        promises.push(promise);
      }
      console.time('total');
      await Promise.all(promises);
      this.calculateValues();
      console.timeEnd('total');
    },
    loadSampleFile: async function () {
      const file = {
        id: Math.random(),
        name: "sample.access.log.gz",
        parsed: null,
        progress: 0,
      };
      this.files.push(file);

      try {
        file.parsed = await fetch("sample.access.log.gz")
          .then(r => r.blob())
          .then((l) => this.parseLog(l, file));
        this.calculateValues();
      } catch (error) {
        console.error("Error loading sample file:", error);
      }
    },
    calculateValues: function (filteredLogs, filteredSessions) {
      let logs = [];
      let sessions = [];
      
      if (filteredLogs && filteredSessions) {
        // If we're given filtered data, use it
        logs = filteredLogs;
        sessions = filteredSessions;
      } else {
        // Otherwise collect from all files
        for (let i = 0; i < this.files.length; i++) {
          if (this.files[i].parsed) {
            logs = logs.concat(this.files[i].parsed.logs);
            sessions = sessions.concat(this.files[i].parsed.sessions);
          }
        }
        logs.sort((a, b) => b.date - a.date);
        sessions.sort((a, b) => b.date - a.date);
        
        // Store the complete dataset for filtering
        this.allLogs = Object.freeze([...logs]);
        this.allSessions = Object.freeze([...sessions]);
        
        // Initialize date range on first load
        if (!this.startDate || !this.endDate) {
          this.initDateRange(logs);
        }
      }

      // Always update the logs data to ensure data tables and visualizations reflect correct data
      this.logs = Object.freeze(logs); 
      this.numberOfRequests = logs.length;
      this.numberOfSessions = sessions.length;

      const statusCodesCounter = { 200: 0, 404: 0, 500: 0 };
      const referrerCounter = {};
      const browserCounter = { Chrome: 0, Firefox: 0, Edge: 0 };
      const urlCounter = {};
      const sessionCounter = {};
      const requestCounter = {};
      const transferCounter = {};
      const countryCounter = {};
      const ipCounter = {};
      const ipData = {};
      const dates = {};
      let totalTransfer = 0;
      const self = this; // Store reference to 'this'

      let splitTime = "hour";
      if (logs.length > 0) {
        if (
          logs[0].date - logs[logs.length - 1].date >
          1000 * 60 * 60 * 24 * 3
        ) {
          splitTime = "day";
        }
      }

      logs.forEach((log) => {
        // Map transfere to transfer for consistency
        if (log.transfere !== undefined && log.transfer === undefined) {
          log.transfer = log.transfere;
        }
        
        totalTransfer += log.transfer || 0;
        statusCodesCounter[log.statusCode] =
          statusCodesCounter[log.statusCode] + 1 || 1;
        if (log.url) {
          urlCounter[log.url] = urlCounter[log.url] + 1 || 1;
        }
        
        // Track IP addresses and their request counts
        if (log.ipAddress) {
          ipCounter[log.ipAddress] = ipCounter[log.ipAddress] + 1 || 1;
          
          // Store the associated country and browser info for each IP
          if (!ipData[log.ipAddress]) {
            ipData[log.ipAddress] = {
              country: log.country || '',
              browser: '',
              userAgent: log.userAgend || '',
              network: self.getNetworkInfo(log.ipAddress) || ''
            };
          }
        }

        let time;
        if (splitTime === "hour") {
          time =
            log.date.toLocaleDateString() +
            " " +
            log.date.getHours().toString().padStart(2, "0") +
            ":00";
          dates[time] = new Date(
            log.date.getFullYear(),
            log.date.getMonth(),
            log.date.getDate(),
            log.date.getHours()
          );
        } else if (splitTime === "day") {
          time = log.date.toLocaleDateString();
          dates[time] = new Date(
            log.date.getFullYear(),
            log.date.getMonth(),
            log.date.getDate()
          );
        }
        
        requestCounter[time] = requestCounter[time] + 1 || 1;
        transferCounter[time] =
          transferCounter[time] + log.transfer || log.transfer || 0;
      });

      sessions.forEach((log) => {
        if (log.referrerDomain && log.referrerDomain !== "-") {
          referrerCounter[log.referrerDomain] =
            referrerCounter[log.referrerDomain] + 1 || 1;
        }
        if (log.browser) {
          browserCounter[log.browser] = browserCounter[log.browser] + 1 || 1;
          
          // Update browser info for this IP if available
          if (log.ipAddress && ipData[log.ipAddress]) {
            ipData[log.ipAddress].browser = log.browser;
          }
        }
        if (log.country) {
          countryCounter[log.country] = countryCounter[log.country] + 1 || 1;
          
          // Update country info for this IP if available
          if (log.ipAddress && ipData[log.ipAddress]) {
            ipData[log.ipAddress].country = log.country;
          }
        }
        
        let time;
        if (splitTime === "hour") {
          time =
            log.date.toLocaleDateString() +
            " " +
            log.date.getHours().toString().padStart(2, "0") +
            ":00";
          dates[time] = new Date(
            log.date.getFullYear(),
            log.date.getMonth(),
            log.date.getDate(),
            log.date.getHours()
          );
        } else if (splitTime === "day") {
          time = log.date.toLocaleDateString();
          dates[time] = new Date(
            log.date.getFullYear(),
            log.date.getMonth(),
            log.date.getDate()
          );
        }
        sessionCounter[time] = sessionCounter[time] + 1 || 1;
      });

      this.transfer = prettyBytes(totalTransfer);

      const chartDataSessions = [];
      for (let date in sessionCounter) {
        chartDataSessions.push([dates[date], sessionCounter[date]]);
      }
      
      // Sort by date for proper line display
      chartDataSessions.sort((a, b) => {
        if (!a[0] || !b[0]) return 0;
        return new Date(a[0]) - new Date(b[0]);
      });
      
      if (chartDataSessions.length === 0) {
        chartDataSessions.push(["2022", 0]);
      } else if (chartDataSessions.length === 1) {
        // If only one data point, add a duplicate point with slight offset
        const dataPoint = [...chartDataSessions[0]];
        if (dataPoint[0] instanceof Date) {
          const date = new Date(dataPoint[0].getTime());
          date.setMinutes(date.getMinutes() + 5);
          chartDataSessions.push([date, dataPoint[1]]);
        }
      }
      
      chartDataSessions.push(["Time", "Sessions"]);
      chartDataSessions.reverse();
      this.chartDataSessions = Object.freeze(chartDataSessions);

      const chartDataRequests = [];
      for (let date in requestCounter) {
        chartDataRequests.push([dates[date], requestCounter[date]]);
      }
      
      // Sort by date for proper line display
      chartDataRequests.sort((a, b) => {
        if (!a[0] || !b[0]) return 0;
        return new Date(a[0]) - new Date(b[0]);
      });
      
      if (chartDataRequests.length === 0) {
        chartDataRequests.push(["2022", 0]);
      } else if (chartDataRequests.length === 1) {
        // If only one data point, add a duplicate point with slight offset
        const dataPoint = [...chartDataRequests[0]];
        if (dataPoint[0] instanceof Date) {
          const date = new Date(dataPoint[0].getTime());
          date.setMinutes(date.getMinutes() + 5);
          chartDataRequests.push([date, dataPoint[1]]);
        }
      }
      
      chartDataRequests.push(["Time", "Requests"]);
      chartDataRequests.reverse();
      this.chartDataRequests = Object.freeze(chartDataRequests);

      const chartDataTransfer = [];
      for (let date in transferCounter) {
        chartDataTransfer.push([
          dates[date],
          { v: transferCounter[date], f: prettyBytes(transferCounter[date]) },
        ]);
      }
      
      // Sort by date for proper line display
      chartDataTransfer.sort((a, b) => {
        if (!a[0] || !b[0]) return 0;
        return new Date(a[0]) - new Date(b[0]);
      });
      
      if (chartDataTransfer.length === 0) {
        chartDataTransfer.push(["2022", 0]);
      } else if (chartDataTransfer.length === 1) {
        // If only one data point, add a duplicate point with slight offset
        const dataPoint = [...chartDataTransfer[0]];
        if (dataPoint[0] instanceof Date) {
          const date = new Date(dataPoint[0].getTime());
          date.setMinutes(date.getMinutes() + 5);
          chartDataTransfer.push([date, dataPoint[1]]);
        }
      }
      
      chartDataTransfer.push(["Time", "Bytes"]);
      chartDataTransfer.reverse();
      this.chartDataTransfer = Object.freeze(chartDataTransfer);

      const chartDataMap = [];
      
      // First add header row
      chartDataMap.push(["Country", "Sessions"]);
      
      // Then add data rows
      for (let country in countryCounter) {
        // Skip invalid or missing country codes
        if (country && country.length === 2) {
          chartDataMap.push([country, countryCounter[country]]);
        }
      }
      
      // Sort by session count (after header row)
      if (chartDataMap.length > 1) {
        const header = chartDataMap.shift();
        chartDataMap.sort((a, b) => b[1] - a[1]);
        chartDataMap.unshift(header);
      }
      
      this.chartDataMap = Object.freeze(chartDataMap);

      const mostStatusCodes = [];
      for (let statusCode in statusCodesCounter) {
        mostStatusCodes.push({
          statusCode: statusCode,
          hits: statusCodesCounter[statusCode],
        });
      }
      mostStatusCodes.sort((a, b) => b.hits - a.hits);
      this.mostStatusCodes = mostStatusCodes.slice(0, 10);

      const mostReferrers = [];
      for (let referrer in referrerCounter) {
        mostReferrers.push({
          referrer: referrer,
          hits: referrerCounter[referrer],
        });
      }
      mostReferrers.sort((a, b) => b.hits - a.hits);
      this.mostReferrers = mostReferrers.slice(0, 10);

      const mostBrowsers = [];
      for (let browser in browserCounter) {
        mostBrowsers.push({
          browser: browser,
          hits: browserCounter[browser],
        });
      }
      mostBrowsers.sort((a, b) => b.hits - a.hits);
      this.mostBrowsers = mostBrowsers.slice(0, 10);

      const mostUrls = [];
      for (let url in urlCounter) {
        mostUrls.push({
          url: url,
          hits: urlCounter[url],
        });
      }
      mostUrls.sort((a, b) => b.hits - a.hits);

      this.mostUrlsWithoutAssets = mostUrls
        .filter((a) => {
          let url = a.url.split("?")[0].split("#")[0];
          let parts = url.split(".");
          const fileending = parts[parts.length - 1];
          return (
            ["png", "css", "js", "jpeg", "jpg", "ico", "svg", "webp", "gif", "cur"].indexOf(
              fileending
            ) === -1
          );
        })
        .slice(0, 10);

      this.mostUrls = mostUrls.slice(0, 10);

      const desktopCount = sessions.filter(
        (s) => s.device === "desktop"
      ).length;
      const mobileCount = sessions.filter((s) => s.device === "mobile").length;
      const tabletCount = sessions.filter((s) => s.device === "tablet").length;
      const deviceSum = desktopCount + mobileCount + tabletCount;
      if (deviceSum > 0) {
        this.devices.desktop.percentage = (desktopCount / deviceSum) * 100;
        this.devices.mobile.percentage = (mobileCount / deviceSum) * 100;
        this.devices.tablet.percentage = (tabletCount / deviceSum) * 100;
      } else {
        this.devices.desktop.percentage = 0;
        this.devices.mobile.percentage = 0;
        this.devices.tablet.percentage = 0;
      }

      const mostIPs = [];
      for (let ip in ipCounter) {
        mostIPs.push({
          ip: ip,
          hits: ipCounter[ip],
          country: ipData[ip] && ipData[ip].country ? ipData[ip].country : '',
          browser: ipData[ip] && ipData[ip].browser ? ipData[ip].browser : '',
          userAgent: ipData[ip] && ipData[ip].userAgent ? ipData[ip].userAgent : '',
          network: ipData[ip] && ipData[ip].network ? ipData[ip].network : (ip === '-' ? 'Unknown' : self.getNetworkInfo(ip))
        });
      }
      mostIPs.sort((a, b) => b.hits - a.hits);
      this.mostIPs = mostIPs.slice(0, 10);
    },
    setStartDate: function() {
      if (this.startDatePicker && this.startTimePicker) {
        const [year, month, day] = this.startDatePicker.split('-');
        const [hours, minutes] = this.startTimePicker.split(':');
        this.startDate = new Date(year, month - 1, day, hours, minutes);
        this.startDateFormatted = this.formatDateTime(this.startDate);
      }
    },
    
    setEndDate: function() {
      if (this.endDatePicker && this.endTimePicker) {
        const [year, month, day] = this.endDatePicker.split('-');
        const [hours, minutes] = this.endTimePicker.split(':');
        this.endDate = new Date(year, month - 1, day, hours, minutes);
        this.endDateFormatted = this.formatDateTime(this.endDate);
      }
    },
    
    formatDateTime: function(date) {
      if (!date) return '';
      return `${date.toLocaleDateString()} ${date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}`;
    },
    
    applyTimeFilter: function() {
      if (this.allLogs.length > 0) {
        let filteredLogs = [...this.allLogs];
        let filteredSessions = [...this.allSessions];
        
        if (this.startDate) {
          filteredLogs = filteredLogs.filter(log => log.date >= this.startDate);
          filteredSessions = filteredSessions.filter(session => session.date >= this.startDate);
        }
        
        if (this.endDate) {
          filteredLogs = filteredLogs.filter(log => log.date <= this.endDate);
          filteredSessions = filteredSessions.filter(session => session.date <= this.endDate);
        }
        
        // Apply the filtered data to logs AND recalculate all visualizations
        this.calculateValues(filteredLogs, filteredSessions);
        this.isFiltered = true;
      }
    },
    
    resetTimeFilter: function() {
      // Reset filter state
      this.isFiltered = false;
      this.activePreset = ''; // Clear active preset
      
      if (this.allLogs && this.allLogs.length > 0 && this.allSessions && this.allSessions.length > 0) {
        // Sort logs for getting date ranges
        const sortedLogs = [...this.allLogs].sort((a, b) => a.date - b.date);
        if (sortedLogs.length > 0) {
          const earliest = new Date(sortedLogs[0].date);
          const latest = new Date(sortedLogs[sortedLogs.length - 1].date);
          
          // Format date picker values
          this.startDatePicker = this.formatDateForPicker(earliest);
          this.endDatePicker = this.formatDateForPicker(latest);
          
          // Format time picker values
          this.startTimePicker = this.formatTimeForPicker(earliest);
          this.endTimePicker = this.formatTimeForPicker(latest);
          
          // Set the actual date objects
          this.startDate = earliest;
          this.endDate = latest;
          
          // Update formatted display
          this.startDateFormatted = this.formatDateTime(earliest);
          this.endDateFormatted = this.formatDateTime(latest);
        }
        
        // Use the reset approach to recalculate everything from scratch
        this.logs = Object.freeze([...this.allLogs]);
        
        // Force recalculation of all values with full dataset
        this.calculateValues(this.allLogs, this.allSessions);
        
        // Trigger update on dashboard components
        this.$nextTick(() => {
          // Ensure charts refresh properly
          if (this.tab === 0) {
            this.tab = 1;
            this.$nextTick(() => { this.tab = 0; });
          } else {
            const currentTab = this.tab;
            this.tab = (this.tab + 1) % 3;
            this.$nextTick(() => { this.tab = currentTab; });
          }
        });
      }
    },
    
    initDateRange: function(logs) {
      if (logs && logs.length > 0) {
        // Sort logs by date
        const sortedLogs = [...logs].sort((a, b) => a.date - b.date);
        
        // Set default date range from earliest to latest log
        const earliest = new Date(sortedLogs[0].date);
        const latest = new Date(sortedLogs[sortedLogs.length - 1].date);
        
        // Format date picker values
        this.startDatePicker = this.formatDateForPicker(earliest);
        this.endDatePicker = this.formatDateForPicker(latest);
        
        // Format time picker values
        this.startTimePicker = this.formatTimeForPicker(earliest);
        this.endTimePicker = this.formatTimeForPicker(latest);
        
        // Set the actual date objects but don't enable filtering
        this.startDate = earliest;
        this.endDate = latest;
        
        // Update formatted display
        this.startDateFormatted = this.formatDateTime(earliest);
        this.endDateFormatted = this.formatDateTime(latest);
        
        // Make sure filtering is not enabled on initial load
        this.isFiltered = false;
      }
    },
    
    formatDateForPicker: function(date) {
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    },
    
    formatTimeForPicker: function(date) {
      return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
    },
    applyPresetRange: function(preset) {
      this.activePreset = preset;
      
      let start = new Date();
      let end = new Date();
      
      switch(preset) {
        case 'today':
          // Start of today
          start.setHours(0, 0, 0, 0);
          break;
          
        case 'yesterday':
          // Start of yesterday
          start.setDate(start.getDate() - 1);
          start.setHours(0, 0, 0, 0);
          // End of yesterday
          end.setDate(end.getDate() - 1);
          end.setHours(23, 59, 59, 999);
          break;
          
        case 'last7days':
          // 7 days ago
          start.setDate(start.getDate() - 7);
          start.setHours(0, 0, 0, 0);
          break;
          
        case 'last30days':
          // 30 days ago
          start.setDate(start.getDate() - 30);
          start.setHours(0, 0, 0, 0);
          break;
          
        case 'thisMonth':
          // Start of this month
          start.setDate(1);
          start.setHours(0, 0, 0, 0);
          break;
          
        case 'lastMonth':
          // Start of last month
          start.setMonth(start.getMonth() - 1);
          start.setDate(1);
          start.setHours(0, 0, 0, 0);
          // End of last month
          end.setDate(0); // Last day of previous month
          end.setHours(23, 59, 59, 999);
          break;
      }
      
      // Update date pickers
      this.startDatePicker = this.formatDateForPicker(start);
      this.endDatePicker = this.formatDateForPicker(end);
      
      // Update time pickers
      this.startTimePicker = this.formatTimeForPicker(start);
      this.endTimePicker = this.formatTimeForPicker(end);
      
      // Set actual date objects
      this.startDate = start;
      this.endDate = end;
      
      // Update formatted display
      this.startDateFormatted = this.formatDateTime(start);
      this.endDateFormatted = this.formatDateTime(end);
      
      // Apply the filter
      if (this.allLogs && this.allLogs.length > 0) {
        let filteredLogs = [...this.allLogs];
        let filteredSessions = [...this.allSessions];
        
        filteredLogs = filteredLogs.filter(log => log.date >= start && log.date <= end);
        filteredSessions = filteredSessions.filter(session => session.date >= start && session.date <= end);
        
        // Apply the filtered data
        this.calculateValues(filteredLogs, filteredSessions);
        this.isFiltered = true;
      }
    },
    showLogDetails: function(item) {
      // Create a copy of the item to avoid modifying the original
      const detailsObj = {...item};
      
      // Order the properties for better readability
      const orderedDetails = {};
      
      // Primary properties to show first (in this order)
      const primaryProps = ['date', 'ipAddress', 'method', 'url', 'statusCode', 'transfer', 'country', 'browser', 'device'];
      
      // Add primary properties first
      primaryProps.forEach(prop => {
        if (detailsObj[prop] !== undefined) {
          orderedDetails[prop] = detailsObj[prop];
        }
      });
      
      // Add remaining properties except 'raw'
      Object.keys(detailsObj).forEach(key => {
        if (!primaryProps.includes(key) && key !== 'raw') {
          orderedDetails[key] = detailsObj[key];
        }
      });
      
      // Add raw data at the end if available
      if (detailsObj.raw) {
        orderedDetails.raw = detailsObj.raw;
      }
      
      this.selectedLogDetails = orderedDetails;
      this.logDetailsDialog = true;
    },
    formatFieldName: function(key) {
      // Format field names for better readability
      const fieldNameMap = {
        'ipAddress': 'IP Address',
        'statusCode': 'Status Code',
        'referrerDomain': 'Referrer Domain',
        'userAgent': 'User Agent',
        'transfere': 'Transfer'
      };
      
      // Return mapped name if available
      if (fieldNameMap[key]) {
        return fieldNameMap[key];
      }
      
      // Otherwise capitalize first letter
      return key.charAt(0).toUpperCase() + key.slice(1);
    },
    getStatusCodeClass: function(statusCode) {
      // Implement your logic to determine the class based on the status code
      if (statusCode >= 200 && statusCode < 300) {
        return 'success';
      } else if (statusCode >= 300 && statusCode < 400) {
        return 'warning';
      } else if (statusCode >= 400 && statusCode < 500) {
        return 'error';
      } else if (statusCode >= 500) {
        return 'error';
      }
      return '';
    },
    toggleTheme: function() {
      this.theme = this.theme === 'dark' ? 'light' : 'dark';
      this.$vuetify.theme.dark = this.theme === 'dark';
      
      // Save theme preference to localStorage
      localStorage.setItem('theme', this.theme);
      
      // Force redraw charts to update colors
      this.$nextTick(() => {
        const currentTab = this.tab;
        this.tab = (this.tab + 1) % 3;
        this.$nextTick(() => {
          this.tab = currentTab;
        });
      });
    },
  },
};
</script>
