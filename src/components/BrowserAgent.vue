<template>
  <span 
    class="browser-wrapper" 
    @click="showDetails"
    tabindex="0"
    @keyup.enter="showDetails"
  >
    <img
      v-if="logo"
      :src="logo"
      height="16"
      class="mr-1"
    />
    <slot>{{ browser }}</slot>
  </span>
</template>

<script>
export default {
  name: 'BrowserAgent',
  props: {
    browser: {
      type: String,
      required: true
    },
    logo: {
      type: String,
      default: null
    }
  },
  methods: {
    showDetails() {
      this.$emit('show-details');
    }
  }
}
</script>

<style scoped>
.browser-wrapper {
  cursor: pointer;
  position: relative;
  border-bottom: 1px dotted rgba(128, 128, 128, 0.4);
  transition: color 0.2s, background-color 0.2s;
  padding: 2px 4px;
  border-radius: 3px;
}
.browser-wrapper:hover {
  text-decoration: underline;
  color: var(--v-primary-base);
  background-color: rgba(139, 0, 0, 0.1);
}
</style> 