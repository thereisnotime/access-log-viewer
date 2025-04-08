<template>
  <v-app :theme="theme">
    <v-app-bar app color="primary" dark>
      <div class="d-flex align-center">
        <v-icon class="mr-2" large>mdi-shield-lock</v-icon>
        <h1>SALV - Security Access Log Viewer</h1>
      </div>

      <v-spacer></v-spacer>

      <v-select
        v-model="timezone"
        :items="timezones"
        label="Timezone"
        dense
        style="max-width: 200px;"
        class="mr-4 mt-5"
        hide-details
        color="white"
        background-color="rgba(255,255,255,0.1)"
      ></v-select>
      
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
              <v-icon x-large color="grey lighten-1" class="mb-3">mdi-upload-outline</v-icon>
              <div>Drag one or more access.log files here.</div>

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

        <!-- Security Analysis Panel -->
        <v-row>
          <v-col cols="12">
            <v-card>
              <v-card-title>
                <v-icon left color="white">mdi-shield-alert</v-icon>
                Security Analysis
              </v-card-title>
              
              <div v-if="allLogs && allLogs.length > 0">
                <v-tabs
                  v-model="securityTab"
                  background-color="transparent"
                  grow
                  id="tabs"
                >
                  <v-tab>
                    <div>Top IPs with Errors</div>
                  </v-tab>
                  <v-tab>
                    <v-icon left>mdi-browser-outline</v-icon>
                    <div>Least Used Browsers</div>
                  </v-tab>
                  <v-tab>
                    <v-icon left>mdi-browser</v-icon>
                    <div>Most Used Browsers</div>
                  </v-tab>
                  <v-tab>
                    <div>Largest Transfers</div>
                  </v-tab>
                  <v-tabs-slider color="primary"></v-tabs-slider>
                </v-tabs>
                <v-tabs-items v-model="securityTab">
                  <!-- Tab 1: Top 20 IPs by 4xx and 5xx errors -->
                  <v-tab-item>
                    <v-card flat>
                      <v-card-text v-if="errorIPs.length > 0">
                        <v-data-table
                          :headers="[
                            { text: 'IP Address', value: 'ip' },
                            { text: 'Error Count', value: 'errorCount' },
                            { text: 'Country', value: 'country' },
                            { text: 'Browser', value: 'browser' },
                            { text: 'Network', value: 'network' }
                          ]"
                          :items="errorIPs"
                          dense
                          :items-per-page="10"
                          :footer-props="{
                            'items-per-page-options': [10, 20, 30, 50, 100],
                            'show-first-last-page': true
                          }"
                          class="elevation-1"
                        >
                          <template v-slot:item.ip="{ item }">
                            <ip-address :ip="item.ip" @find-in-logs="setSearchFilter" />
                          </template>
                          <template v-slot:item.country="{ item }">
                            <span v-if="item.country">
                              <img 
                                v-if="item.country && item.country.length === 2"
                                width="16" 
                                height="12"
                                :src="`https://flagcdn.com/16x12/${item.country.toLowerCase()}.png`"
                                :alt="item.country"
                                class="mr-1"
                              />
                              {{ item.country }}
                            </span>
                          </template>
                          <template v-slot:item.browser="{ item }">
                            <browser-agent 
                              :browser="item.browser" 
                              :logo="browserLogos[item.browser]"
                              @show-details="() => showBrowserDetails({browser: item.browser, hits: 0, percentage: 0})"
                            />
                          </template>
                        </v-data-table>
                      </v-card-text>
                      <v-card-text v-else class="text-center pa-5">
                        <v-icon large color="grey">mdi-alert-circle-outline</v-icon>
                        <div class="grey--text mt-2">No error data available for the selected time range</div>
                      </v-card-text>
                    </v-card>
                  </v-tab-item>
                  <!-- Tab 2: Least Used Browser Agents -->
                  <v-tab-item>
                    <v-card flat>
                      <v-card-text v-if="leastUsedBrowsers.length > 0">
                        <v-data-table
                          :headers="[
                            { text: 'Browser', value: 'browser' },
                            { text: 'Sessions', value: 'hits' },
                            { text: 'Percentage', value: 'percentage' }
                          ]"
                          :items="leastUsedBrowsers"
                          dense
                          :items-per-page="10"
                          :footer-props="{
                            'items-per-page-options': [10, 20, 30, 50, 100],
                            'show-first-last-page': true
                          }"
                          class="elevation-1"
                          @click:row="showBrowserDetails"
                        >
                          <template v-slot:item.browser="{ item }">
                            <browser-agent 
                              :browser="item.browser" 
                              :logo="browserLogos[item.browser]"
                              @show-details="() => showBrowserDetails(item)"
                            />
                          </template>
                          <template v-slot:item.percentage="{ item }">
                            {{ item.percentage.toFixed(2) }}%
                          </template>
                        </v-data-table>
                      </v-card-text>
                      <v-card-text v-else class="text-center pa-5">
                        <v-icon large color="grey">mdi-browser-outline</v-icon>
                        <div class="grey--text mt-2">No browser data available for the selected time range</div>
                      </v-card-text>
                    </v-card>
                  </v-tab-item>
                  <!-- Tab 3: Most Used Browser Agents -->
                  <v-tab-item>
                    <v-card flat>
                      <v-card-text v-if="mostBrowsers.length > 0">
                        <v-data-table
                          :headers="[
                            { text: 'Browser', value: 'browser' },
                            { text: 'Sessions', value: 'hits' },
                            { text: 'Percentage', value: 'percentage' }
                          ]"
                          :items="mostBrowsers"
                          dense
                          :items-per-page="10"
                          :footer-props="{
                            'items-per-page-options': [10, 20, 30, 50, 100],
                            'show-first-last-page': true
                          }"
                          class="elevation-1"
                          @click:row="showBrowserDetails"
                        >
                          <template v-slot:item.browser="{ item }">
                            <browser-agent 
                              :browser="item.browser" 
                              :logo="browserLogos[item.browser]"
                              @show-details="() => showBrowserDetails(item)"
                            />
                          </template>
                          <template v-slot:item.percentage="{ item }">
                            {{ item.percentage.toFixed(2) }}%
                          </template>
                        </v-data-table>
                      </v-card-text>
                      <v-card-text v-else class="text-center pa-5">
                        <v-icon large color="grey">mdi-browser</v-icon>
                        <div class="grey--text mt-2">No browser data available for the selected time range</div>
                      </v-card-text>
                    </v-card>
                  </v-tab-item>
                  <!-- Tab 4: Largest Transfers -->
                  <v-tab-item>
                    <v-card flat>
                      <v-card-text v-if="largestTransfers && largestTransfers.length > 0">
                        <v-data-table
                          :headers="[
                            { text: 'URL', value: 'url' },
                            { text: 'IP Address', value: 'ipAddress' },
                            { text: 'Transfer Size', value: 'transfer' },
                            { text: 'Method', value: 'method' },
                            { text: 'Status', value: 'statusCode' },
                            { text: 'Date', value: 'date' }
                          ]"
                          :items="largestTransfers"
                          dense
                          :items-per-page="10"
                          :footer-props="{
                            'items-per-page-options': [10, 20, 30, 50, 100],
                            'show-first-last-page': true
                          }"
                          class="elevation-1"
                        >
                          <template v-slot:item.ipAddress="{ item }">
                            <ip-address :ip="item.ipAddress" @find-in-logs="setSearchFilter" />
                          </template>
                          <template v-slot:item.statusCode="{ item }">
                            <span :class="getStatusCodeClass(item.statusCode)">
                              {{ item.statusCode }}
                            </span>
                          </template>
                          <template v-slot:item.transfer="{ item }">
                            {{ prettyBytes(item.transfer) }}
                          </template>
                          <template v-slot:item.date="{ item }">
                            {{ formatDate(new Date(item.date)) }}
                          </template>
                        </v-data-table>
                      </v-card-text>
                      <v-card-text v-else class="text-center pa-5">
                        <v-icon large color="grey">mdi-file-download</v-icon>
                        <div class="grey--text mt-2">No transfer data available for the selected time range</div>
                      </v-card-text>
                    </v-card>
                  </v-tab-item>
                </v-tabs-items>
              </div>
              
              <!-- Placeholder when no data loaded -->
              <v-card-text v-else class="text-center pa-8">
                <div class="grey--text mt-2">Upload log files to view security analysis</div>
                <p class="grey--text">Drag and drop or browse for your access log files above</p>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" lg="6">
            <v-card height="100%">
              <v-card-title class="d-flex align-center">
                <v-icon left color="white">mdi-chart-bar</v-icon>
                <span>Summary</span>
              </v-card-title>
              <v-tabs
                v-model="tab"
                background-color="transparent"
                grow
                id="tabs"
              >
                <v-tab>
                  <v-icon class="mb-2">mdi-chart-timeline</v-icon>
                  <div>Sessions</div>
                </v-tab>
                <v-tab>
                  <v-icon class="mb-2">mdi-earth</v-icon>
                  <div>Requests</div>
                </v-tab>
                <v-tab>
                  <v-icon class="mb-2">mdi-format-list-bulleted</v-icon>
                  <div>Traffic</div>
                </v-tab>
                <v-tab>
                  <v-icon class="mb-2">mdi-shield-account</v-icon>
                  <div>Users</div>
                </v-tab>
                <v-tabs-slider color="primary"></v-tabs-slider>
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
                <v-tab-item :transition="false">
                  <v-card flat v-if="tab === 3">
                    <v-card-text v-if="logs.length > 0">
                      <v-simple-table dense>
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
                                <ip-address :ip="item.ip || '-'" @find-in-logs="setSearchFilter" />
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
                    <v-card-text v-else class="text-center pa-5">
                      <v-icon large color="grey">mdi-table-off</v-icon>
                      <div class="grey--text mt-2">No log entries found for the selected time range</div>
                      <v-btn small color="secondary" @click="resetTimeFilter" class="mt-4">Reset Filter</v-btn>
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
                          <ip-address :ip="item.ip || '-'" @find-in-logs="setSearchFilter" />
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
              <v-card-title id="logs-section"> Logs </v-card-title>
              <v-card-text v-if="logs.length > 0">
                <v-text-field
                  v-model="search"
                  label="Search"
                  single-line
                  hide-details
                  clearable
                  prepend-icon="mdi-magnify"
                  @click:clear="clearSearchFilter"
                ></v-text-field>

                <v-data-table
                  dense
                  :headers="headers"
                  :items="logs"
                  :search="search"
                  :footer-props="{
                    'items-per-page-options': [10, 20, 30],
                    'show-first-last-page': true
                  }"
                  @click:row="showLogDetails"
                >
                  <template v-slot:item.ipAddress="{ item }">
                    <ip-address :ip="item.ipAddress" @find-in-logs="setSearchFilter" />
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
                    {{ formatDate(new Date(item.date)) }}
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

      <v-btn
        v-show="showScrollTop"
        fab
        fixed
        bottom
        right
        small
        color="primary"
        @click="scrollToTop"
        class="mb-12 mr-4"
        style="opacity: 0.8;"
      >
        <v-icon>mdi-arrow-up</v-icon>
      </v-btn>
    </v-main>
    <v-footer padless dark>
      <v-card flat tile width="100%" class="primary lighten-1 text-center">
        <v-card-text>
          <v-btn class="mx-4" icon>
            <a href="https://github.com/thereisnotime/access-log-viewer"
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
                      <browser-agent 
                        :browser="value" 
                        :logo="browserLogos[value]"
                        @show-details="() => showBrowserDetails({browser: value, hits: 0, percentage: 0})"
                      />
                    </span>
                    <span v-else>{{ value }}</span>
                  </td>
                </tr>
              </tbody>
            </template>
          </v-simple-table>
          
          <div class="mt-4" v-if="selectedLogDetails && selectedLogDetails.raw">
            <h3>Raw Log Entry</h3>
            <pre class="log-raw">{{ selectedLogDetails.raw }}</pre>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- Browser Details Dialog -->
    <v-dialog v-model="browserDetailsDialog" max-width="800">
      <v-card>
        <v-card-title class="headline primary white--text">
          Browser Details
          <v-spacer></v-spacer>
          <v-btn icon @click="browserDetailsDialog = false">
            <v-icon color="white">mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text class="pt-4">
          <v-row>
            <v-col cols="12">
              <v-card flat>
                <v-card-title>
                  <span v-if="selectedBrowserDetails">
                    <img
                      v-if="browserLogos[selectedBrowserDetails.browser]"
                      :src="browserLogos[selectedBrowserDetails.browser]"
                      height="24"
                      width="24"
                      class="mr-3"
                    />
                    {{ selectedBrowserDetails.browser }}
                  </span>
                </v-card-title>
                <v-card-text>
                  <div v-if="selectedBrowserDetails">
                    <div class="d-flex mb-2">
                      <div class="font-weight-bold mr-2">Sessions:</div>
                      <div>{{ selectedBrowserDetails.hits }}</div>
                    </div>
                    <div class="d-flex mb-2">
                      <div class="font-weight-bold mr-2">Percentage:</div>
                      <div>{{ selectedBrowserDetails.percentage.toFixed(2) }}%</div>
                    </div>
                    <div class="mt-4">
                      <div class="font-weight-bold mb-2">Sample User Agent Strings:</div>
                      <div v-if="browserUserAgents && browserUserAgents.length > 0">
                        <v-card outlined class="pa-2 mb-2" v-for="(ua, index) in browserUserAgents" :key="index">
                          <pre class="user-agent-pre">{{ ua }}</pre>
                        </v-card>
                      </div>
                      <div v-else class="grey--text text-center pa-4">
                        No user agent data available
                      </div>
                    </div>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<style scoped>
.drag-hover {
  background-color: rgba(0, 0, 0, 0.05);
}

#dropzone {
  border: 4px dashed var(--v-primary-base);
  text-align: center;
  padding: 4em 1em;
  transition: all 0.2s;
}

#files {
  display: none;
}

.success {
  color: green;
}
.warning {
  color: orange;
}
.error {
  color: red;
}

.ip-address {
  cursor: pointer;
  color: var(--v-primary-base);
}

.log-raw, 
.user-agent-pre {
  white-space: pre-wrap;
  word-break: break-all;
  background-color: var(--v-background-base, #f5f5f5);
  padding: 8px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 0.9rem;
  max-height: 300px;
  overflow-y: auto;
}

.theme--dark .log-raw,
.theme--dark .user-agent-pre {
  background-color: #333;
  color: #eee;
}

#tabs .v-tabs-bar {
  height: 100px !important; /* Increase height to add more space */
  padding-top: 0; /* Remove top padding */
}
#tabs .v-tab {
  flex-direction: column;
  padding-bottom: 0; /* Remove bottom padding */
  margin-bottom: 30px; /* Add bottom margin instead */
}
/* Add space between card title and tabs */
.v-card__title + .v-tabs {
  margin-top: 15px;
}
/* Override the v-tabs-slider color */
#tabs .v-tabs-slider {
  background-color: #8B0000 !important; /* Primary dark red color */
  bottom: 0 !important; /* Reset the slider position */
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
import BrowserAgent from "./components/BrowserAgent.vue";
import { GChart } from "vue-google-charts";
const prettyBytes = require("pretty-bytes");

export default {
  components: {
    IconTrash,
    IconDesktop,
    IconMobile,
    IconTablet,
    IpAddress,
    BrowserAgent,
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
    largestTransfers: [], // Store largest transfers by size
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
    securityTab: null,
    errorIPs: [],
    leastUsedBrowsers: [],
    browserDetailsDialog: false,
    selectedBrowserDetails: null,
    browserUserAgents: [],
    timezone: 'UTC',
    timezones: [
      { text: 'UTC', value: 'UTC' },
      { text: 'Africa/Cairo', value: 'Africa/Cairo' },
      { text: 'Africa/Johannesburg', value: 'Africa/Johannesburg' },
      { text: 'Africa/Lagos', value: 'Africa/Lagos' },
      { text: 'Africa/Nairobi', value: 'Africa/Nairobi' },
      { text: 'America/Anchorage', value: 'America/Anchorage' },
      { text: 'America/Bogota', value: 'America/Bogota' },
      { text: 'America/Chicago', value: 'America/Chicago' },
      { text: 'America/Denver', value: 'America/Denver' },
      { text: 'America/Los_Angeles', value: 'America/Los_Angeles' },
      { text: 'America/Mexico_City', value: 'America/Mexico_City' },
      { text: 'America/New_York', value: 'America/New_York' },
      { text: 'America/Phoenix', value: 'America/Phoenix' },
      { text: 'America/Santiago', value: 'America/Santiago' },
      { text: 'America/Sao_Paulo', value: 'America/Sao_Paulo' },
      { text: 'America/Toronto', value: 'America/Toronto' },
      { text: 'Asia/Bangkok', value: 'Asia/Bangkok' },
      { text: 'Asia/Dubai', value: 'Asia/Dubai' },
      { text: 'Asia/Hong_Kong', value: 'Asia/Hong_Kong' },
      { text: 'Asia/Jakarta', value: 'Asia/Jakarta' },
      { text: 'Asia/Jerusalem', value: 'Asia/Jerusalem' },
      { text: 'Asia/Kolkata', value: 'Asia/Kolkata' },
      { text: 'Asia/Seoul', value: 'Asia/Seoul' },
      { text: 'Asia/Shanghai', value: 'Asia/Shanghai' },
      { text: 'Asia/Singapore', value: 'Asia/Singapore' },
      { text: 'Asia/Tokyo', value: 'Asia/Tokyo' },
      { text: 'Australia/Melbourne', value: 'Australia/Melbourne' },
      { text: 'Australia/Perth', value: 'Australia/Perth' },
      { text: 'Australia/Sydney', value: 'Australia/Sydney' },
      { text: 'Europe/Amsterdam', value: 'Europe/Amsterdam' },
      { text: 'Europe/Athens', value: 'Europe/Athens' },
      { text: 'Europe/Berlin', value: 'Europe/Berlin' },
      { text: 'Europe/Istanbul', value: 'Europe/Istanbul' },
      { text: 'Europe/Kiev', value: 'Europe/Kiev' },
      { text: 'Europe/London', value: 'Europe/London' },
      { text: 'Europe/Madrid', value: 'Europe/Madrid' },
      { text: 'Europe/Moscow', value: 'Europe/Moscow' },
      { text: 'Europe/Paris', value: 'Europe/Paris' },
      { text: 'Europe/Rome', value: 'Europe/Rome' },
      { text: 'Europe/Sofia', value: 'Europe/Sofia' },
      { text: 'Europe/Stockholm', value: 'Europe/Stockholm' },
      { text: 'Europe/Zurich', value: 'Europe/Zurich' },
      { text: 'Pacific/Auckland', value: 'Pacific/Auckland' },
      { text: 'Pacific/Honolulu', value: 'Pacific/Honolulu' }
    ],
    showScrollTop: false,
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
      const browserData = {}; // Store browser data including sample user agents
      const dates = {};
      let totalTransfer = 0;
      const self = this; // Store reference to 'this'

      // Define fields that may contain user agent strings
      const userAgentFields = ['userAgent', 'userAgend', 'user_agent', 'ua'];
      
      // Function to extract user agent from an object
      const extractUserAgent = (obj) => {
        for (const field of userAgentFields) {
          if (obj[field] && typeof obj[field] === 'string') {
            return obj[field];
          }
        }
        return null;
      };
      
      // Browser name mapping for consistency
      const normalizeBrowserName = (browser) => {
        if (!browser) return '';
        
        // Standard naming
        if (browser.includes('Chrome') && browser.includes('WebView')) {
          return 'Chrome WebView';
        } else if (browser === 'Chrome' || browser === 'Chromium') {
          return 'Chrome';
        } else if (browser === 'Firefox' || browser === 'Mozilla') {
          return 'Firefox';
        } else if (browser === 'Safari' || browser === 'Mobile Safari') {
          return 'Safari';
        } else if (browser.includes('Edge') || browser === 'Edg') {
          return 'Edge';
        } else if (browser.includes('IE') || browser.includes('Internet Explorer')) {
          return 'IE';
        } else if (browser.includes('Opera')) {
          return 'Opera';
        }
        
        return browser;
      };

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
        
        // Capture user agent data for browser if available
        if (log.browser) {
          const normalizedBrowser = normalizeBrowserName(log.browser);
          log.browser = normalizedBrowser; // Normalize for consistency
          
          const ua = extractUserAgent(log);
          if (ua) {
            if (!browserData[normalizedBrowser]) {
              browserData[normalizedBrowser] = { userAgents: [] };
            }
            if (!browserData[normalizedBrowser].userAgents.includes(ua) && 
                browserData[normalizedBrowser].userAgents.length < 5) {
              browserData[normalizedBrowser].userAgents.push(ua);
            }
          }
        }
        
        // Track IP addresses and their request counts
        if (log.ipAddress) {
          ipCounter[log.ipAddress] = ipCounter[log.ipAddress] + 1 || 1;
          
          // Store the associated country and browser info for each IP
          if (!ipData[log.ipAddress]) {
            ipData[log.ipAddress] = {
              country: log.country || '',
              browser: '',
              userAgent: extractUserAgent(log) || '',
              network: self.getNetworkInfo(log.ipAddress) || ''
            };
          }
        }

        let time;
        let timeDate;
        
        // Format with timezone properly for chart aggregation
        try {
          // Create a formatted date string that respects the selected timezone
          // Get a timezone-adjusted date object
          const adjustedDate = new Date(log.date.toLocaleString('en-US', { timeZone: this.timezone }));
          
          if (splitTime === "hour") {
            // Format as localized hour for aggregation key
            time = adjustedDate.toLocaleDateString() + " " + 
                  adjustedDate.getHours().toString().padStart(2, "0") + ":00";
                  
            // Store the timezone-adjusted date for the chart
            timeDate = new Date(
              adjustedDate.getFullYear(),
              adjustedDate.getMonth(),
              adjustedDate.getDate(),
              adjustedDate.getHours()
            );
          } else if (splitTime === "day") {
            // Format as localized day for aggregation key
            time = adjustedDate.toLocaleDateString();
            
            // Store the timezone-adjusted date for the chart
            timeDate = new Date(
              adjustedDate.getFullYear(),
              adjustedDate.getMonth(),
              adjustedDate.getDate()
            );
          }
          
          dates[time] = timeDate;
        } catch (e) {
          console.error("Error applying timezone to chart data:", e);
          
          // Fallback to original behavior
          if (splitTime === "hour") {
            time = log.date.toLocaleDateString() + " " + 
                  log.date.getHours().toString().padStart(2, "0") + ":00";
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
        }
        
        requestCounter[time] = requestCounter[time] + 1 || 1;
        transferCounter[time] =
          transferCounter[time] + log.transfer || log.transfer || 0;
      });

      sessions.forEach((session) => {
        if (session.referrerDomain && session.referrerDomain !== "-") {
          referrerCounter[session.referrerDomain] =
            referrerCounter[session.referrerDomain] + 1 || 1;
        }
        if (session.browser) {
          const normalizedBrowser = normalizeBrowserName(session.browser);
          session.browser = normalizedBrowser; // Normalize for consistency
          
          browserCounter[normalizedBrowser] = browserCounter[normalizedBrowser] + 1 || 1;
          
          // Capture user agent data for browser if available 
          const ua = extractUserAgent(session);
          if (ua) {
            if (!browserData[normalizedBrowser]) {
              browserData[normalizedBrowser] = { userAgents: [] };
            }
            if (!browserData[normalizedBrowser].userAgents.includes(ua) && 
                browserData[normalizedBrowser].userAgents.length < 5) {
              browserData[normalizedBrowser].userAgents.push(ua);
            }
          }
          
          // Update browser info for this IP if available
          if (session.ipAddress && ipData[session.ipAddress]) {
            ipData[session.ipAddress].browser = session.browser;
          }
        }
        if (session.country) {
          countryCounter[session.country] = countryCounter[session.country] + 1 || 1;
          
          // Update country info for this IP if available
          if (session.ipAddress && ipData[session.ipAddress]) {
            ipData[session.ipAddress].country = session.country;
          }
        }
        
        let time;
        let timeDate;
        
        // Format with timezone properly for chart aggregation
        try {
          // Create a formatted date string that respects the selected timezone
          // Get a timezone-adjusted date object
          const adjustedDate = new Date(session.date.toLocaleString('en-US', { timeZone: this.timezone }));
          
          if (splitTime === "hour") {
            // Format as localized hour for aggregation key
            time = adjustedDate.toLocaleDateString() + " " + 
                  adjustedDate.getHours().toString().padStart(2, "0") + ":00";
                  
            // Store the timezone-adjusted date for the chart
            timeDate = new Date(
              adjustedDate.getFullYear(),
              adjustedDate.getMonth(),
              adjustedDate.getDate(),
              adjustedDate.getHours()
            );
          } else if (splitTime === "day") {
            // Format as localized day for aggregation key
            time = adjustedDate.toLocaleDateString();
            
            // Store the timezone-adjusted date for the chart
            timeDate = new Date(
              adjustedDate.getFullYear(),
              adjustedDate.getMonth(),
              adjustedDate.getDate()
            );
          }
          
          dates[time] = timeDate;
        } catch (e) {
          console.error("Error applying timezone to chart data:", e);
          
          // Fallback to original behavior
          if (splitTime === "hour") {
            time = session.date.toLocaleDateString() + " " + 
                  session.date.getHours().toString().padStart(2, "0") + ":00";
            dates[time] = new Date(
              session.date.getFullYear(),
              session.date.getMonth(),
              session.date.getDate(),
              session.date.getHours()
            );
          } else if (splitTime === "day") {
            time = session.date.toLocaleDateString();
            dates[time] = new Date(
              session.date.getFullYear(),
              session.date.getMonth(),
              session.date.getDate()
            );
          }
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

      // Calculate top IPs with 4xx and 5xx errors
      const errorIPCounter = {};
      const errorIPData = {};
      
      logs.forEach(log => {
        const statusCode = parseInt(log.statusCode);
        // Check if this is a 4xx or 5xx error
        if (statusCode >= 400 && log.ipAddress) {
          // Count errors for this IP
          errorIPCounter[log.ipAddress] = (errorIPCounter[log.ipAddress] || 0) + 1;
          
          // Store or update associated data
          if (!errorIPData[log.ipAddress]) {
            errorIPData[log.ipAddress] = {
              country: log.country || '',
              browser: '',
              network: self.getNetworkInfo(log.ipAddress) || ''
            };
          }
        }
      });
      
      // Check sessions for browser info for IPs that had errors
      sessions.forEach(session => {
        if (session.ipAddress && errorIPData[session.ipAddress] && session.browser) {
          errorIPData[session.ipAddress].browser = session.browser;
        }
        if (session.ipAddress && errorIPData[session.ipAddress] && session.country) {
          errorIPData[session.ipAddress].country = session.country;
        }
      });
      
      // Create array of IPs with error counts
      const errorIPs = [];
      for (let ip in errorIPCounter) {
        errorIPs.push({
          ip: ip,
          errorCount: errorIPCounter[ip],
          country: errorIPData[ip] ? errorIPData[ip].country : '',
          browser: errorIPData[ip] ? errorIPData[ip].browser : '',
          network: errorIPData[ip] ? errorIPData[ip].network : self.getNetworkInfo(ip)
        });
      }
      
      // Sort by error count and take top 20
      errorIPs.sort((a, b) => b.errorCount - a.errorCount);
      this.errorIPs = errorIPs.slice(0, 20);
      
      // Calculate total sessions for percentage calculations
      const totalSessions = sessions.length;
      
      // Add percentage data to mostBrowsers
      const browsersWithPercentage = mostBrowsers.map(item => ({
        ...item,
        percentage: totalSessions > 0 ? (item.hits / totalSessions) * 100 : 0,
        userAgents: browserData[item.browser]?.userAgents || []
      }));
      
      // Set most used browsers (with percentage)
      this.mostBrowsers = browsersWithPercentage.slice(0, 20);
      
      // Calculate least used browsers (with percentage)
      const leastUsedBrowsers = [...browsersWithPercentage]
        .filter(item => item.hits > 0) // Exclude browsers with 0 hits
        .sort((a, b) => a.hits - b.hits); // Sort ascending by hit count
        
      this.leastUsedBrowsers = leastUsedBrowsers.slice(0, 20);

      // Process largest transfers (by size)
      // Make sure transfer value exists before sorting
      this.largestTransfers = logs
        .filter(log => typeof log.transfer === 'number' && log.transfer > 0)
        .slice()
        .sort((a, b) => b.transfer - a.transfer)
        .slice(0, 20);
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
      try {
        return date.toLocaleString('en-US', { 
          timeZone: this.timezone,
          year: 'numeric', 
          month: 'short', 
          day: 'numeric',
          hour: '2-digit', 
          minute: '2-digit',
          second: '2-digit'
        });
      } catch (e) {
        console.error("Error formatting date with timezone:", e);
        return date.toLocaleString();
      }
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
    setSearchFilter: function(ip) {
      // Set search filter to the IP address and scroll to logs section
      this.search = ip;
      
      // Scroll to the logs section
      this.$nextTick(() => {
        const logsElement = document.getElementById('logs-section');
        if (logsElement) {
          logsElement.scrollIntoView({ behavior: 'smooth' });
        }
      });
    },
    showBrowserDetails: function(item) {
      // Store browser details
      this.selectedBrowserDetails = {...item};
      
      // If the browser item already has user agent data from our calculations
      if (item.userAgents && item.userAgents.length > 0) {
        this.browserUserAgents = [...item.userAgents];
        this.browserDetailsDialog = true;
        return;
      }
      
      // Get sample user agent strings for this browser
      this.browserUserAgents = [];
      const userAgentFields = ['userAgent', 'userAgend', 'user_agent', 'ua'];
      
      // Function to find the first valid user agent field in a log object
      const extractUserAgent = (obj) => {
        for (const field of userAgentFields) {
          if (obj[field] && typeof obj[field] === 'string') {
            return obj[field];
          }
        }
        return null;
      };
      
      // List of browser names to check (add variations for each browser)
      const browserNameVariants = this.getBrowserNameVariants(item.browser);
      console.log("Looking for user agent data for browser variants:", browserNameVariants);
      
      // Find up to 5 unique user agent strings for this browser from logs
      if (this.allLogs && this.allLogs.length > 0) {
        const userAgents = new Set();
        
        for (const log of this.allLogs) {
          if (log.browser && browserNameVariants.includes(log.browser)) {
            const ua = extractUserAgent(log);
            if (ua) {
              userAgents.add(ua);
              if (userAgents.size >= 5) break;
            }
          }
        }
        
        this.browserUserAgents = Array.from(userAgents);
      }
      
      // If no user agents found in logs, try sessions
      if (this.browserUserAgents.length === 0 && this.allSessions && this.allSessions.length > 0) {
        const userAgents = new Set();
        
        for (const session of this.allSessions) {
          if (session.browser && browserNameVariants.includes(session.browser)) {
            const ua = extractUserAgent(session);
            if (ua) {
              userAgents.add(ua);
              if (userAgents.size >= 5) break;
            }
          }
        }
        
        this.browserUserAgents = Array.from(userAgents);
      }
      
      // If still no user agents, look for partial matches
      if (this.browserUserAgents.length === 0) {
        const simplifiedBrowserName = item.browser.toLowerCase().replace(/\s+/g, '');
        const userAgents = new Set();
        
        // Check logs for partial matches
        for (const log of this.allLogs) {
          if (log.browser && log.browser.toLowerCase().replace(/\s+/g, '').includes(simplifiedBrowserName)) {
            const ua = extractUserAgent(log);
            if (ua) {
              userAgents.add(ua);
              if (userAgents.size >= 5) break;
            }
          }
        }
        
        // Check sessions for partial matches
        if (userAgents.size < 5) {
          for (const session of this.allSessions) {
            if (session.browser && 
                session.browser.toLowerCase().replace(/\s+/g, '').includes(simplifiedBrowserName)) {
              const ua = extractUserAgent(session);
              if (ua && !userAgents.has(ua)) {
                userAgents.add(ua);
                if (userAgents.size >= 5) break;
              }
            }
          }
        }
        
        if (userAgents.size > 0) {
          this.browserUserAgents = Array.from(userAgents);
        }
      }
      
      // If still no user agents found, look directly in raw user agent strings
      if (this.browserUserAgents.length === 0) {
        const userAgents = new Set();
        const keywords = this.getBrowserKeywords(item.browser);
        
        // Check logs for keyword matches in user agent strings
        for (const log of this.allLogs) {
          const ua = extractUserAgent(log);
          if (ua && this.containsAnyKeyword(ua.toLowerCase(), keywords)) {
            userAgents.add(ua);
            if (userAgents.size >= 5) break;
          }
        }
        
        // Check sessions for keyword matches in user agent strings
        if (userAgents.size < 5) {
          for (const session of this.allSessions) {
            const ua = extractUserAgent(session);
            if (ua && this.containsAnyKeyword(ua.toLowerCase(), keywords) && !userAgents.has(ua)) {
              userAgents.add(ua);
              if (userAgents.size >= 5) break;
            }
          }
        }
        
        if (userAgents.size > 0) {
          this.browserUserAgents = Array.from(userAgents);
        }
      }
      
      // Final fallback: if still no user agents, show any 5 user agents as examples
      if (this.browserUserAgents.length === 0) {
        const userAgents = new Set();
        
        // Just get any user agents at this point
        for (const log of this.allLogs) {
          const ua = extractUserAgent(log);
          if (ua) {
            userAgents.add(ua);
            if (userAgents.size >= 5) break;
          }
        }
        
        if (userAgents.size < 5) {
          for (const session of this.allSessions) {
            const ua = extractUserAgent(session);
            if (ua && !userAgents.has(ua)) {
              userAgents.add(ua);
              if (userAgents.size >= 5) break;
            }
          }
        }
        
        if (userAgents.size > 0) {
          this.browserUserAgents = Array.from(userAgents);
          console.log("Using generic user agent examples as fallback");
        }
      }
      
      // Log browser identification data for debugging
      console.log(`Looking for user agent data for: ${item.browser}`, {
        foundUserAgents: this.browserUserAgents.length,
        logCount: this.allLogs?.length || 0,
        sessionCount: this.allSessions?.length || 0
      });
      
      // Open the dialog
      this.browserDetailsDialog = true;
    },
    
    getBrowserNameVariants: function(browserName) {
      // Create variations of browser names that might appear in logs
      const variants = [browserName];
      
      // Add common variations
      if (browserName.includes('Chrome')) {
        variants.push('Chrome');
        variants.push('Chromium');
        if (browserName.includes('WebView')) {
          variants.push('Android WebView');
          variants.push('Android');
          variants.push('Mobile');
        }
      } else if (browserName.includes('Firefox')) {
        variants.push('Firefox');
        variants.push('Mozilla');
      } else if (browserName.includes('Safari')) {
        variants.push('Safari');
        variants.push('Mobile Safari');
        variants.push('WebKit');
      } else if (browserName.includes('Edge')) {
        variants.push('Edge');
        variants.push('Edg');
        variants.push('EdgiOS');
        variants.push('Edge Chromium');
      } else if (browserName.includes('IE') || browserName.includes('Internet Explorer')) {
        variants.push('IE');
        variants.push('Internet Explorer');
        variants.push('MSIE');
      } else if (browserName.includes('Opera')) {
        variants.push('Opera');
        variants.push('OPR');
      }
      
      return variants;
    },
    
    getBrowserKeywords: function(browserName) {
      // Create keywords to search for in user agent strings
      const keywords = [];
      
      if (browserName.includes('Chrome')) {
        keywords.push('chrome');
        if (browserName.includes('WebView')) {
          keywords.push('webview');
          keywords.push('android');
          keywords.push('mobile');
          keywords.push('wv');
        }
      } else if (browserName.includes('Firefox')) {
        keywords.push('firefox');
        keywords.push('gecko');
      } else if (browserName.includes('Safari')) {
        keywords.push('safari');
        keywords.push('webkit');
        keywords.push('applewebkit');
      } else if (browserName.includes('Edge')) {
        keywords.push('edge');
        keywords.push('edg/');
        keywords.push('edgios');
      } else if (browserName.includes('IE') || browserName.includes('Internet Explorer')) {
        keywords.push('msie');
        keywords.push('trident');
      } else if (browserName.includes('Opera')) {
        keywords.push('opera');
        keywords.push('opr/');
      } else {
        // Add lowercase version of browser name without spaces
        keywords.push(browserName.toLowerCase().replace(/\s+/g, ''));
      }
      
      return keywords;
    },
    
    containsAnyKeyword: function(text, keywords) {
      for (const keyword of keywords) {
        if (text.includes(keyword)) {
          return true;
        }
      }
      return false;
    },
    clearSearchFilter: function() {
      this.search = '';
    },
    refreshData: function() {
      // Reset filter state if applicable
      if (this.isFiltered) {
        this.resetTimeFilter();
      } else if (this.allLogs && this.allLogs.length > 0) {
        // Force recalculation of all values
        this.calculateValues(this.allLogs, this.allSessions);
        
        // Trigger UI update
        this.$nextTick(() => {
          const message = `Data refreshed: ${this.numberOfRequests} requests, ${this.numberOfSessions} sessions`;
          alert(message);
        });
      }
    },
    scrollToTop: function() {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    handleScroll() {
      // Show scroll-to-top button when scrolled down more than 300px
      this.showScrollTop = window.scrollY > 300;
    },
    formatDate: function(date) {
      if (!date) return '';
      try {
        return date.toLocaleString('en-US', { 
          timeZone: this.timezone,
          year: 'numeric', 
          month: 'short', 
          day: 'numeric',
          hour: '2-digit', 
          minute: '2-digit'
        });
      } catch (e) {
        console.error("Error formatting date with timezone:", e);
        return date.toLocaleString();
      }
    }
  },
  mounted() {
    // Add scroll listener for scroll-to-top button
    window.addEventListener('scroll', this.handleScroll);
  },
  beforeDestroy() {
    // Remove scroll listener when component is destroyed
    window.removeEventListener('scroll', this.handleScroll);
  },
  watch: {
    timezone() {
      // When timezone changes, update all date displays
      this.$forceUpdate();
      
      // Update formatted dates
      if (this.startDate) {
        this.startDateFormatted = this.formatDateTime(this.startDate);
      }
      if (this.endDate) {
        this.endDateFormatted = this.formatDateTime(this.endDate);
      }
      
      // Force update on all charts and tables
      if (this.allLogs && this.allLogs.length > 0) {
        // Recalculate values based on current filter status
        if (this.isFiltered) {
          this.applyTimeFilter();
        } else {
          // Force recalculation of all values with full dataset
          this.calculateValues(this.allLogs, this.allSessions);
        }
        
        // Trigger update on dashboard components
        this.$nextTick(() => {
          // Ensure charts refresh properly by temporarily switching tabs
          const currentTab = this.tab;
          this.tab = (this.tab + 1) % 3;
          this.$nextTick(() => { 
            this.tab = currentTab;
          });
        });
      }
    }
  },
};
</script>
