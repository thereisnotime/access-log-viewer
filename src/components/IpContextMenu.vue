<template>
  <v-menu
    v-model="showMenu"
    :position-x="x"
    :position-y="y"
    absolute
    offset-y
  >
    <v-list dense>
      <v-list-item dense>
        <v-list-item-title class="text-center font-weight-bold">{{ ip }}</v-list-item-title>
      </v-list-item>
      <v-divider></v-divider>
      <v-list-item
        v-for="(item, index) in menuItems"
        :key="index"
        dense
        @click="openUrl(item.url)"
      >
        <v-list-item-title>{{ item.title }}</v-list-item-title>
      </v-list-item>
    </v-list>
  </v-menu>
</template>

<script>
export default {
  name: 'IpContextMenu',
  props: {
    ip: {
      type: String,
      required: true
    },
    show: {
      type: Boolean,
      default: false
    },
    x: {
      type: Number,
      default: 0
    },
    y: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      showMenu: this.show,
    }
  },
  watch: {
    show(val) {
      this.showMenu = val;
    },
    showMenu(val) {
      if (!val) {
        this.$emit('close');
      }
    }
  },
  computed: {
    menuItems() {
      return [
        { 
          title: 'AbuseIPDB Lookup', 
          url: `https://www.abuseipdb.com/check/${this.ip}`
        },
        { 
          title: 'MXToolbox Blacklist Check', 
          url: `https://mxtoolbox.com/SuperTool.aspx?action=blacklist%3a${this.ip}&run=toolpage`
        },
        { 
          title: 'DNS Lookup', 
          url: `https://www.nslookup.io/domains/${this.ip}/dns-records/`
        },
        { 
          title: 'WHOIS/IP Info', 
          url: `https://browserleaks.com/ip/${this.ip}`
        }
      ];
    }
  },
  methods: {
    openUrl(url) {
      window.open(url, '_blank');
      this.showMenu = false;
    }
  }
}
</script>

<style scoped>
.v-list-item {
  min-height: 36px;
}
</style> 